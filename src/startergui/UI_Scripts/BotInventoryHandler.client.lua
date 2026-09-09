-- created 11/19/25
-- updated 11/19/25

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local GS = RS:WaitForChild("Game Settings")
local Settings = require(GS.Settings)
local Utilities = require(Modules.Utilities)
local spr = Utilities.spr

--// Remotes
local Remotes = RS:WaitForChild("Remotes")

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Variables
local UI = player.PlayerGui:WaitForChild("UI")
local frame = UI.Canvas.Frames.Inventory.Bots
local playerData = player.Data.PlayerData
local botCapacity = player.NonSaveValues.BotCapacity
local this = UI.UI_Scripts.BotInventoryHandler

--// Functions
local toggle = true
toggleOtherBotFrames = function(botFrame)
	toggle = not toggle
	for _, otherBotFrame in pairs(frame:GetChildren()) do
		if not otherBotFrame:IsA("ViewportFrame") then continue end
		if otherBotFrame == botFrame then continue end
		otherBotFrame.Visible = toggle
	end
	if not toggle then
		this.EditTemplate:Clone().Parent = frame
		this.SetTemplate:Clone().Parent = frame
	else
		if frame:FindFirstChild("EditTemplate") then
			frame.EditTemplate:Destroy()
		end
		if frame:FindFirstChild("SetTemplate") then
			frame.SetTemplate:Destroy()
		end
	end
end

for _, botFrame in pairs(frame:GetChildren()) do
	if not (botFrame:IsA("Frame") and botFrame.Name == "BotTemplate") then continue end
	if not botFrame:FindFirstChild("SelectButton") then continue end
	
	local button = botFrame.SelectButton
	local buttonSize = button.Size
	local fields = button.Fields
	
	button.Activated:Connect(function()
		--toggleOtherBotFrames(botFrame)
	end)

	button.MouseEnter:Connect(function()
		Utilities.Audio.PlayAudio("Hover")
		button.TextTransparency = 1
		button.UIStroke.Enabled = false
		fields.Visible = true
		spr.target(button, 0.6, 4, {
			Size = UDim2.fromScale(buttonSize.X.Scale * 1.05, buttonSize.Y.Scale * 1.05)
		})
	end)

	button.MouseLeave:Connect(function()
		button.TextTransparency = 0
		button.UIStroke.Enabled = true
		fields.Visible = false
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
			Size = UDim2.fromScale(buttonSize.X.Scale * 1.05, buttonSize.Y.Scale * 1.05)
		})
	end)
end