local IconManager = {}

--// Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Utilities = require(Modules.Utilities)
local Icon = require(Modules.IconManager.Icon)

--// Variables
local this = Modules.IconManager
local player = Players.LocalPlayer
local UI = player.PlayerGui.UI

--// Icons
local settingsIcon = Icon.new()
    :setName("Settings")
    :bindEvent("deselected", function()
        Utilities.UI.DisplayFrame(UI.Canvas.Frames:FindFirstChild("Settings"), this.Settings)
    end)
    :oneClick()
    :setImage(this.Settings:GetAttribute("ImageID"))
    
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

function IconManager.getRebirthIcon()
    return rebirthIcon
end

return IconManager