--[[
    DA HOOD + JAILBIRD v2.0 - LOADER WITH KEY SYSTEM
    
    This script loads the key system first, then loads the main script after validation.
    
    🔐 Key Link: https://work.ink/2JiA/d653afbe-06a3-4fc9-ba5f-674b59ebcbbd
    
    Features:
    ✅ Work.ink key system integration
    ✅ Auto-save keys (users only enter once)
    ✅ Professional UI
    ✅ Loads full Da Hood + Jailbird script after validation
]]

print("🔐 Da Hood + Jailbird Ultimate - Key System Loader")
print("⏳ Loading key system...")

-- ============================================================================
-- LOAD KEY SYSTEM MODULE
-- ============================================================================

-- ⚠️ IMPORTANT: Upload key_system.lua to your GitHub and replace the URL below!
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/yazan1010111testing/pengu/refs/heads/main/key_system.lua?t=" .. tick()))()

-- ============================================================================
-- CONFIGURE KEY SYSTEM
-- ============================================================================

KeySystem.Config.LinkId = "2JiA"
KeySystem.Config.ScriptName = "Da Hood + Jailbird Ultimate"
KeySystem.Config.ScriptVersion = "v2.0"
KeySystem.Config.SaveKey = true
KeySystem.Config.DeleteToken = false
KeySystem.Config.VerifyIP = false

print("✅ Key system loaded!")
print("🔗 Key Link: " .. KeySystem.Config.KeyLink)

-- ============================================================================
-- INITIALIZE KEY SYSTEM
-- ============================================================================

local success, err = pcall(function()
    KeySystem:Initialize(function()
        print("✅ Key validated! Loading main script...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        -- ============================================================================
        -- LOAD MAIN SCRIPT AFTER KEY VALIDATION
        -- ============================================================================
        
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yazan1010111testing/pengu/refs/heads/main/obfuscated_script-1783699957873.lua"))()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎉 Script fully loaded! Enjoy!")
    end)
end)

if not success then
    warn("❌ ERROR:", err)
    warn("Key system failed to initialize!")
end

print("⏳ Waiting for key validation...")
print("💡 Click 'Get Key' button to get your key!")
