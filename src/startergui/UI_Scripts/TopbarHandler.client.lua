--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Icon = require(RS:WaitForChild("Icon"))
local Utilities = require(Modules.Utilities)
local spr = Utilities.spr

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Variables
local blur = game:GetService("Lighting"):WaitForChild("LCBlurEffect")
local fov = game:GetService("Workspace"):WaitForChild("Camera")
local UI = player.PlayerGui.UI
local buttonsFrame = UI.Canvas.Buttons
local UIFrames = UI.Canvas.Frames
local buttons = {}
local frames = {}

--// Constants
local DEBOUNCE = .35
local BLUR_SHOWN = 15
local BLUR_HIDDEN = 0
local FOV_NORMAL = 70
local FOV_ADJUSTED = 60

--// Main
local settings = Icon.new()
    :setName("Settings")
    :setImage("rbxassetid://11713339600", "Deselected")
    :setImage("rbxassetid://134515081025675", "Selected")
    :bindEvent("deselected", function()
	    Utilities.UI.DisplayFrame(UIFrames.Settings, script.Settings)
    end)
    :oneClick()