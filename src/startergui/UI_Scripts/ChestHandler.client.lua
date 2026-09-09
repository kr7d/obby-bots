-- created 11/23/2025
-- updated 11/23/2025

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Utilities = require(Modules.Utilities)
local spr = Utilities.spr
	
--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil


--// Variables
local button = player.PlayerGui.UI.OpenChest.Chest.Tap
local buttonSize = button.Size

button.MouseEnter:Connect(function()
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
	spr.target(button, 0.6, 4, {
		Size = UDim2.fromScale(buttonSize.X.Scale, buttonSize.Y.Scale)
	})
end)

button.MouseButton1Up:Connect(function()
	spr.target(button, 0.6, 4, {
		Size = UDim2.fromScale(buttonSize.X.Scale * 1.1, buttonSize.Y.Scale * 1.1)
	})
end)