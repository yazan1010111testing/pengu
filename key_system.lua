--[[
    WORK.INK KEY SYSTEM v2
    Secure key validation system using work.ink API v2
    
    Features:
    ✅ Secure key validation with work.ink v2 API
    ✅ Modern UI with animations
    ✅ Key copying to clipboard
    ✅ IP address verification (optional)
    ✅ Auto-save validated keys
    ✅ Anti-bypass protection
    
    Setup Instructions:
    1. Go to https://dashboard.work.ink/
    2. Create a shortened link with destination: https://work.ink/token
    3. Copy your shortened link (e.g., https://work.ink/abc123)
    4. Replace "YOUR_LINK_ID" below with your link ID
]]

local KeySystem = {}

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
KeySystem.Config = {
    -- ✅ CONFIGURED: Your work.ink link
    -- Full link with token parameter
    
    LinkId = "2JiA", -- Your work.ink Link ID
    FullLink = "https://work.ink/2JiA/d653afbe-06a3-4fc9-ba5f-674b59ebcbbd", -- Your complete link
    
    -- Generated automatically (don't change these)
    KeyLink = "", -- Will be set to your full link
    ValidateEndpoint = "https://work.ink/_api/v2/token/isValid/", -- work.ink v2 API
    
    -- Settings (you can customize these)
    ScriptName = "Da Hood + Jailbird Ultimate",
    ScriptVersion = "v2.0",
    SaveKey = true, -- Save valid keys locally (users don't need to re-enter)
    VerifyIP = false, -- Verify IP address matches (keep false for Roblox)
    DeleteToken = false, -- Single-use keys - set true for one-time use only
    MaxAttempts = 5, -- Max failed attempts before cooldown
    CooldownTime = 30, -- Cooldown in seconds after max attempts
}

-- Auto-generate key link (use the full link with token parameter)
KeySystem.Config.KeyLink = KeySystem.Config.FullLink

-- Variables
local LocalPlayer = Players.LocalPlayer
local KeyValidated = false
local FailedAttempts = 0
local LastAttemptTime = 0

-- Get user's IP (for verification if enabled)
local function GetUserIP()
    local success, ip = pcall(function()
        local response = game:HttpGet("https://api.ipify.org?format=text")
        return response
    end)
    return success and ip or "unknown"
end

-- Storage
local function SaveKey(key)
    if not KeySystem.Config.SaveKey then return end
    
    pcall(function()
        writefile("dahoodjailbird_key.txt", key)
    end)
end

local function LoadKey()
    if not KeySystem.Config.SaveKey then return nil end
    
    local success, key = pcall(function()
        return readfile("dahoodjailbird_key.txt")
    end)
    
    return success and key or nil
end

-- API Validation
local function ValidateKey(key)
    print("[Key System DEBUG] Starting validation...")
    print("[Key System DEBUG] Input key:", key)
    
    -- Cooldown check
    if tick() - LastAttemptTime < KeySystem.Config.CooldownTime and FailedAttempts >= KeySystem.Config.MaxAttempts then
        local remainingTime = math.ceil(KeySystem.Config.CooldownTime - (tick() - LastAttemptTime))
        return false, "Too many failed attempts. Wait " .. remainingTime .. "s"
    end
    
    -- Basic validation
    if not key or key == "" or #key < 10 then
        return false, "Please enter a valid key"
    end
    
    -- Clean the key (remove spaces, dashes, etc.)
    key = key:gsub("%s+", ""):gsub("-", "")
    print("[Key System DEBUG] Cleaned key:", key)
    
    -- Build API URL
    local apiUrl = KeySystem.Config.ValidateEndpoint .. key
    
    -- Add optional parameters
    local params = {}
    if KeySystem.Config.DeleteToken then
        table.insert(params, "deleteToken=1")
    end
    
    if #params > 0 then
        apiUrl = apiUrl .. "?" .. table.concat(params, "&")
    end
    
    print("[Key System DEBUG] API URL:", apiUrl)
    
    -- Make API request
    local success, response = pcall(function()
        return game:HttpGet(apiUrl)
    end)
    
    if not success then
        print("[Key System DEBUG] HTTP Request failed:", response)
        LastAttemptTime = tick()
        FailedAttempts = FailedAttempts + 1
        return false, "Connection error. Check your internet."
    end
    
    print("[Key System DEBUG] API Response:", response)
    
    -- Parse JSON response
    local decoded
    success, decoded = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success then
        print("[Key System DEBUG] JSON Parse failed:", decoded)
        LastAttemptTime = tick()
        FailedAttempts = FailedAttempts + 1
        return false, "Invalid response from server"
    end
    
    print("[Key System DEBUG] Decoded response:")
    for k, v in pairs(decoded) do
        print("  ", k, "=", v)
    end
    
    -- Check if key is valid
    if decoded.valid == true then
        -- Optional: Verify IP address
        if KeySystem.Config.VerifyIP and decoded.info and decoded.info.byIp then
            local userIP = GetUserIP()
            if userIP ~= "unknown" and decoded.info.byIp ~= userIP then
                LastAttemptTime = tick()
                FailedAttempts = FailedAttempts + 1
                return false, "IP mismatch. Key tied to different IP."
            end
        end
        
        -- Key is valid!
        KeyValidated = true
        SaveKey(key)
        FailedAttempts = 0
        
        -- Log key info (for debugging)
        if decoded.info then
            print("[Key System] Token validated!")
            print("[Key System] Link ID:", decoded.info.linkId)
            print("[Key System] Created:", decoded.info.createdAt)
            if decoded.deleted then
                print("[Key System] Token was single-use and has been deleted")
            end
        end
        
        return true, "Key validated successfully!"
    else
        -- Invalid key
        print("[Key System DEBUG] Key validation failed - valid =", decoded.valid)
        LastAttemptTime = tick()
        FailedAttempts = FailedAttempts + 1
        return false, "Invalid key. Please get a new one."
    end
end

-- UI Creation
local function CreateUI()
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KeySystemUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Use CoreGui if available, otherwise PlayerGui
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 450, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame
    
    -- Corner
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 12)
    TopCorner.Parent = TopBar
    
    -- Fix bottom corners
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 12)
    TopBarFix.Position = UDim2.new(0, 0, 1, -12)
    TopBarFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Parent = TopBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = KeySystem.Config.ScriptName
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Version
    local Version = Instance.new("TextLabel")
    Version.Name = "Version"
    Version.Size = UDim2.new(0, 60, 1, 0)
    Version.Position = UDim2.new(1, -70, 0, 0)
    Version.BackgroundTransparency = 1
    Version.Text = KeySystem.Config.ScriptVersion
    Version.TextColor3 = Color3.fromRGB(150, 150, 150)
    Version.TextSize = 14
    Version.Font = Enum.Font.Gotham
    Version.TextXAlignment = Enum.TextXAlignment.Right
    Version.Parent = TopBar
    
    -- Description
    local Description = Instance.new("TextLabel")
    Description.Name = "Description"
    Description.Size = UDim2.new(1, -40, 0, 40)
    Description.Position = UDim2.new(0, 20, 0, 65)
    Description.BackgroundTransparency = 1
    Description.Text = "Please enter your key to continue"
    Description.TextColor3 = Color3.fromRGB(180, 180, 180)
    Description.TextSize = 14
    Description.Font = Enum.Font.Gotham
    Description.TextWrapped = true
    Description.Parent = MainFrame
    
    -- Key Input Container
    local InputContainer = Instance.new("Frame")
    InputContainer.Name = "InputContainer"
    InputContainer.Size = UDim2.new(1, -40, 0, 45)
    InputContainer.Position = UDim2.new(0, 20, 0, 115)
    InputContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = MainFrame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = InputContainer
    
    -- Key Input
    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Size = UDim2.new(1, -20, 1, -10)
    KeyInput.Position = UDim2.new(0, 10, 0, 5)
    KeyInput.BackgroundTransparency = 1
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Enter your key here..."
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    KeyInput.TextSize = 14
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = InputContainer
    
    -- Get Key Button
    local GetKeyButton = Instance.new("TextButton")
    GetKeyButton.Name = "GetKeyButton"
    GetKeyButton.Size = UDim2.new(1, -40, 0, 45)
    GetKeyButton.Position = UDim2.new(0, 20, 0, 175)
    GetKeyButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    GetKeyButton.BorderSizePixel = 0
    GetKeyButton.Text = "Get Key"
    GetKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyButton.TextSize = 15
    GetKeyButton.Font = Enum.Font.GothamBold
    GetKeyButton.AutoButtonColor = false
    GetKeyButton.Parent = MainFrame
    
    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 8)
    GetKeyCorner.Parent = GetKeyButton
    
    -- Validate Button
    local ValidateButton = Instance.new("TextButton")
    ValidateButton.Name = "ValidateButton"
    ValidateButton.Size = UDim2.new(1, -40, 0, 45)
    ValidateButton.Position = UDim2.new(0, 20, 0, 235)
    ValidateButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
    ValidateButton.BorderSizePixel = 0
    ValidateButton.Text = "Validate Key"
    ValidateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValidateButton.TextSize = 15
    ValidateButton.Font = Enum.Font.GothamBold
    ValidateButton.AutoButtonColor = false
    ValidateButton.Parent = MainFrame
    
    local ValidateCorner = Instance.new("UICorner")
    ValidateCorner.CornerRadius = UDim.new(0, 8)
    ValidateCorner.Parent = ValidateButton
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -40, 0, 20)
    StatusLabel.Position = UDim2.new(0, 20, 1, -25)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = MainFrame
    
    -- Dragging
    local dragging = false
    local dragInput, dragStart, startPos
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Button Animations
    local function ButtonHover(button, hoverColor, normalColor)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
        end)
    end
    
    ButtonHover(GetKeyButton, Color3.fromRGB(70, 130, 255), Color3.fromRGB(60, 120, 255))
    ButtonHover(ValidateButton, Color3.fromRGB(60, 210, 110), Color3.fromRGB(50, 200, 100))
    
    -- Get Key Button Logic
    GetKeyButton.MouseButton1Click:Connect(function()
        StatusLabel.Text = "Opening key link..."
        StatusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        
        pcall(function()
            if setclipboard then
                setclipboard(KeySystem.Config.KeyLink)
                StatusLabel.Text = "Link copied to clipboard!"
            end
        end)
        
        task.wait(0.5)
        
        -- Try to open link
        pcall(function()
            if syn then
                syn.request({
                    Url = "http://localhost:6463/rpc?v=1",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Origin"] = "https://discord.com"
                    },
                    Body = HttpService:JSONEncode({
                        cmd = "BROWSER_OPEN",
                        args = {url = KeySystem.Config.KeyLink}
                    })
                })
            end
        end)
        
        task.wait(2)
        StatusLabel.Text = ""
    end)
    
    -- Validate Button Logic
    ValidateButton.MouseButton1Click:Connect(function()
        print("[Key System] Button clicked!")
        local key = KeyInput.Text
        print("[Key System] Got key from input:", key)
        
        StatusLabel.Text = "Validating..."
        StatusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        ValidateButton.Text = "Validating..."
        
        task.wait(0.5)
        
        print("[Key System] About to validate...")
        local success, message = ValidateKey(key)
        print("[Key System] Validation result:", success, message)
        
        if success then
            StatusLabel.Text = message
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            ValidateButton.Text = "Success!"
            ValidateButton.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
            
            task.wait(1)
            
            -- Fade out
            TweenService:Create(MainFrame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1
            }):Play()
            
            for _, obj in ipairs(MainFrame:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    TweenService:Create(obj, TweenInfo.new(0.5), {
                        TextTransparency = 1
                    }):Play()
                end
                if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                    TweenService:Create(obj, TweenInfo.new(0.5), {
                        BackgroundTransparency = 1,
                        ImageTransparency = 1
                    }):Play()
                end
            end
            
            task.wait(0.5)
            ScreenGui:Destroy()
        else
            StatusLabel.Text = message
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            ValidateButton.Text = "Validate Key"
            
            -- Shake animation
            local originalPos = ValidateButton.Position
            for i = 1, 3 do
                ValidateButton.Position = originalPos + UDim2.new(0, 5, 0, 0)
                task.wait(0.05)
                ValidateButton.Position = originalPos - UDim2.new(0, 5, 0, 0)
                task.wait(0.05)
            end
            ValidateButton.Position = originalPos
        end
    end)
    
    -- Enter key to validate
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            ValidateButton.MouseButton1Click:Fire()
        end
    end)
    
    return ScreenGui
end

-- Main Function
function KeySystem:Initialize(callback)
    -- Check saved key first
    local savedKey = LoadKey()
    if savedKey then
        print("[Key System] Checking saved key...")
        local success, message = ValidateKey(savedKey)
        
        if success then
            print("[Key System] Saved key valid! Loading script...")
            task.wait(0.5)
            callback()
            return
        else
            print("[Key System] Saved key invalid: " .. message)
        end
    end
    
    -- Show UI
    print("[Key System] Showing key system UI...")
    local ui = CreateUI()
    
    -- Wait for validation
    while not KeyValidated do
        task.wait(0.5)
    end
    
    print("[Key System] Key validated! Loading script...")
    callback()
end

function KeySystem:IsValidated()
    return KeyValidated
end

return KeySystem
