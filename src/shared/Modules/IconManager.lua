local IconManager = {}

--// Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Utilities = require(Modules.Utilities)
local Icon = require(Modules.IconManager.Icon)
local GS = RS:WaitForChild("Game Settings")
local FeatureFlags = require(GS.FeatureFlags)

--// Variables
local this = Modules.IconManager
local player = Players.LocalPlayer
local UI = player.PlayerGui:WaitForChild("UI")

--// Icons
local settingsIcon = Icon.new()
    :setName("Settings")
    :bindEvent("deselected", function()
        Utilities.UI.DisplayFrame(UI.Canvas.Frames:FindFirstChild("Settings"), this.Settings)
    end)
    :oneClick()
    :setImage(this.Settings:GetAttribute("ImageID"))


local profileIcon = if FeatureFlags.isEnabled("ProfileIcon") then Icon.new() -- TODO: Delete flag
    :setName("Profile")
    :bindEvent("deselected", function()
        Utilities.UI.DisplayFrame(UI.Canvas.Frames:FindFirstChild("Profile"), this.Profile)
    end)
    :oneClick()
    :setImage(this.Profile:GetAttribute("ImageID"))
else nil
    
local rebirthIcon = Icon.new()
    :setName("Rebirth")
    :bindEvent("deselected", function()
        Utilities.UI.DisplayFrame(UI.Canvas.Frames:FindFirstChild("Rebirth"), this.Rebirth)
    end)
    :oneClick()
    :setImage(this.Rebirth:GetAttribute("ImageID"))

--// Getters
function IconManager.getSettingsIcon()
    return settingsIcon
end

function IconManager.getProfileIcon()
    return profileIcon
end

function IconManager.getRebirthIcon()
    return rebirthIcon
end

return IconManager