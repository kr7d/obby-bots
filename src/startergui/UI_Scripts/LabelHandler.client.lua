--// Services
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local MarketPlaceService = game:GetService("MarketplaceService")

--// Remotes
local Remotes = RS:WaitForChild("Remotes")
local FindBotIDToOverride = Remotes.FindBotIDToOverride

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Modules
local Modules = RS.Modules
local Utilities = require(Modules.Utilities)

--// Variables
local playerData = player.Data.PlayerData
local nonSaveValues = player.NonSaveValues
local UI = player.PlayerGui.UI
local frame = UI.Canvas.Credits
local creditsLabel = frame.CreditsLabel
local statusLabel = frame.StatusLabel

local tweenInfo = TweenInfo.new(
	1, -- Time
	Enum.EasingStyle.Linear, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching its goal)
	0 -- DelayTime
)

--* Display when player gains/loses credits *--
local oldCredits = nil
playerData.Credits:GetPropertyChangedSignal("Value"):Connect(function()
	local newCredits = playerData.Credits.Value
	creditsLabel.Text = Utilities.Short.en(newCredits).."¢"
	
	if oldCredits ~= nil then
		local profit = newCredits - oldCredits
		local xPosition = math.random(0, 25)/100
		local clone = statusLabel:Clone()
		clone.Parent = frame
		clone.Position = UDim2.new(xPosition, 0, 0.25, 0)
		
		if profit >= 0 then
			clone.TextColor3 = Color3.fromRGB(0,255,0)
			clone.Text = "+"
		elseif profit < 0 then
			clone.TextColor3 = Color3.fromRGB(255,0,0)
			clone.Text = ""
		else
			clone.TextColor3 = Color3.fromRGB(200,200,200)
			clone.Text = ""
		end
		
		clone.Text = clone.Text..tostring(profit).."¢"
		task.spawn(function()
			local tween = TweenService:Create(clone, tweenInfo, {
				Position = UDim2.new(xPosition, 0, 0, 0),
				TextTransparency = 1;
			})
			tween:Play()
		end)
	end
	oldCredits = newCredits
end)

statusLabel.Text = ""



--* Initialize text for Slot 4 BuyButton *--
local slot4 = UI.Canvas.Frames.Inventory.Slots:FindFirstChild("4")
local Gamepass = RS:WaitForChild("Gamepasses").ExtraBot
local GamepassInfo

local Succes, Error = pcall(function()
	GamepassInfo = MarketPlaceService:GetProductInfo(Gamepass.Value, Enum.InfoType.GamePass)
end)

slot4.Locked.BuyButton.Text = "\u{E002}"..GamepassInfo.PriceInRobux



--* Handle Inventory button's CapacityLabel *--
local inventoryButton = UI.Canvas.Buttons.InventoryButton

local function displayIfFull()
	local isFull =  nonSaveValues.NumOfSlotsUsed.Value >= nonSaveValues.BotCapacity.Value
	if isFull then
		inventoryButton.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(214, 34, 24)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 152, 0))
		}
		inventoryButton.CapacityLabel.Text = "FULL"
	else
		inventoryButton.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(192, 152, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 255, 0))
		}
	end
end

local function updateCapacityLabel()
	inventoryButton.CapacityLabel.Text = tostring(nonSaveValues.NumOfSlotsUsed.Value).."/"..tostring(nonSaveValues.BotCapacity.Value)
end

updateCapacityLabel()

nonSaveValues.NumOfSlotsUsed:GetPropertyChangedSignal("Value"):Connect(function()
	updateCapacityLabel()
	displayIfFull()
end)

nonSaveValues.BotCapacity:GetPropertyChangedSignal("Value"):Connect(function()
	updateCapacityLabel()
	displayIfFull()
end)



--* Update CurrentObbyLabel when the current obby changes *--
local currentObbyLabel = UI.Canvas.Status.CurrentObbyLabel

local function initializeCurrentObbyLabel()
	currentObbyLabel.Text = "Play an obby!"
	currentObbyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end

initializeCurrentObbyLabel()

nonSaveValues.CurrentObby.Changed:Connect(function(value)
	if value == "NONE" then initializeCurrentObbyLabel() return end
	currentObbyLabel.Text = "Playing "..nonSaveValues.CurrentObby.Value
	currentObbyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end)



--* Update RecordingLabel when recording starts/stops *--
local recordingLabel = UI.Canvas.Status.RecordingLabel
local isRecording = nonSaveValues.IsRecording

local function initializeRecordingLabel()
	recordingLabel.Text = ""
	recordingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end

local function warnIfMaxBots()
	local botIDtoOverride = FindBotIDToOverride:InvokeServer(0)
	if not botIDtoOverride then
		recordingLabel.Text = "Can't record - No available slots!"
		recordingLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		return
	end
end

nonSaveValues.CurrentObby.Changed:Connect(function(value)
	if value == "NONE" then initializeRecordingLabel() return end
	warnIfMaxBots()
end)

local thread = nil

isRecording.Changed:Connect(function(value)
	if value == true then
		local botIDtoOverride = FindBotIDToOverride:InvokeServer(0)
		if botIDtoOverride then
			recordingLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

			if thread ~= nil then -- cancel thread if it exists
				task.cancel(thread)
				thread = nil
			end

			thread = task.spawn(function()
				while true do
					recordingLabel.Text = "Recording Slot #"..tostring(botIDtoOverride).."."
					task.wait(0.5)
					recordingLabel.Text = "Recording Slot #"..tostring(botIDtoOverride)..".."
					task.wait(0.5)
					recordingLabel.Text = "Recording Slot #"..tostring(botIDtoOverride).."..."
					task.wait(0.5)
				end
			end)
		end
	else
		if thread ~= nil then
			task.cancel(thread)
			thread = nil
		end
		initializeRecordingLabel()
		warnIfMaxBots()
	end
end)

--// Main
initializeRecordingLabel()