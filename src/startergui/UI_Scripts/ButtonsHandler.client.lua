-- created 11/12/2025


--[[

Handles UI for Inventory, Shop, Spectate

]]

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
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

--// Magic Variables
local DEBOUNCE = .35
local BLUR_SHOWN = 15
local BLUR_HIDDEN = 0
local FOV_NORMAL = 70
local FOV_ADJUSTED = 60

--// Initialization
for _, instance in pairs(buttonsFrame:GetChildren()) do
	if instance:IsA("ImageButton") then
		table.insert(buttons, instance)
	end
end

for _, instance in pairs(UIFrames:GetChildren()) do
	if instance:IsA("Frame") then
		table.insert(frames, instance)
	end
end

--// Main
for _, button in pairs(buttons) do
	local buttonSize = button.Size
	local targetFrame = button.TargetFrame.Value
	local config = button:FindFirstChild("Configuration")
	local lastActivation = 0
	
	button.MouseEnter:Connect(function()
		Utilities.Audio.PlayAudio("Hover")
		spr.target(button, 0.6, 4, {
			Size = UDim2.fromScale(buttonSize.X.Scale * 1.1, buttonSize.Y.Scale * 1.1)
		})
	end)

	button.MouseLeave:Connect(function()
		spr.target(button, 0.6, 4, {
			Size = UDim2.fromScale(buttonSize.X.Scale, buttonSize.Y.Scale)
		})
	end)

	button.MouseButton1Down:Connect(function()
		Utilities.Audio.PlayAudio("Click")
		spr.target(button, 0.6, 4, {
			Size = UDim2.fromScale(buttonSize.X.Scale, buttonSize.Y.Scale)
		})
	end)

	button.MouseButton1Up:Connect(function()
		spr.target(button, 0.6, 4, {
			Size = UDim2.fromScale(buttonSize.X.Scale * 1.1, buttonSize.Y.Scale * 1.1)
		})
	end)

	button.Activated:Connect(function()
		Utilities.UI.DisplayFrame(targetFrame, config)
		if button.Name == "InventoryButton" and not player:FindFirstChild("TutorialCompleted") then
			if button:FindFirstChild("Spotlight") then
				button.Spotlight:Destroy()
			end
			button.Interactable = false
		end
	end)
end