--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Icon = require(RS:WaitForChild("Icon"))
local Utilities = require(Modules.Utilities)

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Variables
local UI = player.PlayerGui.UI

--// Main
for _, config in script:GetChildren() do
    local icon = Icon.new()
        :setName(config.Name)
        :bindEvent("deselected", function()
            Utilities.UI.DisplayFrame(UI.Canvas.Frames:FindFirstChild(config.Name), config)
        end)
        :oneClick()
    if config:GetAttribute("ImageID") then
        icon:setImage(config:GetAttribute("ImageID"))
    end
end