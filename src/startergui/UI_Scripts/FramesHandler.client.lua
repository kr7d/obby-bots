-- created 11/11/2025
-- last updated 11/14/2025

--// Services
local RS = game:GetService("ReplicatedStorage")
local GS = RS:WaitForChild("Game Settings")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Utilities = require(Modules.Utilities)
local spr = Utilities.spr
local Settings = require(GS.Settings)

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Variables
local UI = player.PlayerGui.UI
local framesFolder = UI.Canvas.Frames
local blur = game:GetService("Lighting"):WaitForChild("LCBlurEffect")
local fov = game:GetService("Workspace"):WaitForChild("Camera")

--// Magic Variables
local SHOWN_POSITION = Settings["SHOWN_POSITION"]
local HIDDEN_POSITION = Settings["HIDDEN_POSITION"]

--// Main
for _, frame in pairs(framesFolder:GetChildren()) do
	if not frame:IsA("Frame") then continue end
	if not frame:FindFirstChild("Buttons") then continue end
	for _, button in pairs(frame.Buttons:GetChildren()) do
		if not button:IsA("ImageButton") then continue end
		local targetFrame = button.TargetFrame.Value
		local buttonSize = button.Size
		button.Activated:Connect(function()
			Utilities.UI.DisplaySection(targetFrame)
			for _, v in pairs(frame.Buttons:GetChildren()) do
				if not v:IsA("ImageButton") then continue end
				v.ImageColor3 = Color3.fromRGB(255,255,255)
			end
			button.ImageColor3 = Color3.fromRGB(102, 191, 255)
		end)

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
	end
	
	local exitButton = frame.Buttons.Exit
	local exitButtonSize = exitButton.Size

	exitButton.MouseEnter:Connect(function()
		Utilities.Audio.PlayAudio("Hover")
		spr.target(exitButton, 0.6, 4, {
			Size = UDim2.fromScale(exitButtonSize.X.Scale * 1.1, exitButtonSize.Y.Scale * 1.1)
		})
	end)

	exitButton.MouseLeave:Connect(function()
		spr.target(exitButton, 0.6, 4, {
			Size = UDim2.fromScale(exitButtonSize.X.Scale, exitButtonSize.Y.Scale)
		})
	end)

	exitButton.MouseButton1Down:Connect(function()
		Utilities.Audio.PlayAudio("Click")
		spr.target(exitButton, 0.6, 4, {
			Size = UDim2.fromScale(exitButtonSize.X.Scale, exitButtonSize.Y.Scale)
		})
	end)

	exitButton.MouseButton1Up:Connect(function()
		spr.target(exitButton, 0.6, 4, {
			Size = UDim2.fromScale(exitButtonSize.X.Scale * 1.1, exitButtonSize.Y.Scale * 1.1)
		})
	end)

	exitButton.Activated:Connect(function()
		spr.target(blur, 0.6, 4, {Size = 0})
		spr.target(fov, 0.6, 4, {FieldOfView = 70})
		spr.target(frame, 1, 4, {Size = UDim2.fromScale(0, 0)})
		task.wait(.35)
		frame.Visible = false
	end)
end