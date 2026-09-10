-- created 12/12/2025
-- updated 4/4/2026

--// Services
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

--// Module
local Modules = RS:WaitForChild("Modules")
local Utilities = require(Modules.Utilities)
local Settings = require(RS["Game Settings"].Settings)

--// Remotes
local Remotes = RS:WaitForChild("Remotes")
local BotReplay = Remotes:WaitForChild("BotReplay")

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char) character = char end)

--// UI
local UI = player.PlayerGui.UI
local Frames = UI.Canvas.Frames
local Buttons = UI.Canvas.Buttons

--// Variables
local WorkspaceBots = workspace.Bots[player.Name]
local Data = player.Data
local PlayerData = Data.PlayerData
local NonSaveValues = player.NonSaveValues
local this = player.PlayerScripts.Client

--// Initialization
local function initializeUI()
	local playerData = player.Data.PlayerData
	local UI = player.PlayerGui.UI
	-- Capacity Label
	local capacityLabel = UI.Canvas.Buttons.InventoryButton.CapacityLabel
	capacityLabel.Text = tostring(NonSaveValues.NumOfSlotsUsed.Value).."/"..tostring(NonSaveValues.BotCapacity.Value)
	if NonSaveValues.NumOfSlotsUsed.Value >= NonSaveValues.BotCapacity.Value then
		UI.Canvas.Buttons.InventoryButton.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(214, 34, 24)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 152, 0))
		}
		capacityLabel.Text = "FULL"
	end
	-- Slots
	local slotsFrame = UI.Canvas.Frames.Inventory.Slots
	for i = 2, Settings["MAX_BOT_SLOT"] do
		local ownsBot = playerData["OwnsBot"..i]
		slotsFrame[i].Locked.Visible = not ownsBot.Value
		slotsFrame[i].Fields.Interactable = ownsBot.Value
		slotsFrame[i].Fields.ResetButton.Visible = ownsBot.Value
	end

	-- Credits Label
	local creditsLabel = UI.Canvas.Credits.CreditsLabel
	creditsLabel.Text = Utilities.Short.en(playerData.Credits.Value).."¢"
end

initializeUI()

if UserInputService.TouchEnabled then
	local MobileResetButton = this:WaitForChild("MobileResetButton")
	MobileResetButton.Parent = player.PlayerGui.Record.Canvas.Topbar
	MobileResetButton.Visible = false
	NonSaveValues:WaitForChild("CurrentObby").Changed:Connect(function()
		MobileResetButton.Visible = NonSaveValues.CurrentObby.Value ~= "NONE"
	end)
	MobileResetButton.Activated:Connect(function()
		if NonSaveValues.CurrentObby.Value ~= "NONE" then
			local startZone = workspace.Zones.StartZones[NonSaveValues.CurrentObby.Value]
			if not character:FindFirstChild("HumanoidRootPart") then
				warn("HumanoidRootPart not found")
				return
			end
			local legToHRP = character["Left Leg"].Size.Y + (character.HumanoidRootPart.Size.Y/2)
			local yOffset = legToHRP - (startZone.Size.Y / 2)
			local destination = startZone.CFrame + Vector3.new(0, yOffset, 0)
			character.HumanoidRootPart.CFrame = destination
		end
	end)
end


--// User Input
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	-- Quick restart
	if input.KeyCode == Enum.KeyCode.R and NonSaveValues.CurrentObby.Value ~= "NONE" then
		local startZone = workspace.Zones.StartZones[NonSaveValues.CurrentObby.Value]
		if not character:FindFirstChild("HumanoidRootPart") then
			warn("HumanoidRootPart not found")
			return
		end
		local legToHRP = character["Left Leg"].Size.Y + (character.HumanoidRootPart.Size.Y/2)
		local yOffset = legToHRP - (startZone.Size.Y / 2)
		local destination = startZone.CFrame + Vector3.new(0, yOffset, 0)
		character.HumanoidRootPart.CFrame = destination
	end
end)



--// Chests
function InitProbabilityFrames()
	for _, Chest in pairs(RS.Chests:GetChildren()) do
		local ChestModel = game.Workspace.Map.Chests[Chest.Name]
		local BillboardGui = this.ChestProbability:Clone()
		BillboardGui.Parent = player.PlayerGui
		BillboardGui.Adornee = ChestModel.Model.Main
		
		-- Sort bots to display easy bots top-left, rare bots bottom-right
		local bots = {}
		for key, prob in pairs(Chest.Probabilities:GetAttributes()) do
			local BotName = (string.gsub(key, "_", " "))
			table.insert(bots, { Name = BotName, Probability = prob })
			table.sort(bots, function(a, b)
				return a.Probability > b.Probability
			end)
		end
		
		for i, bot in pairs(bots) do
			local BotName = bot.Name
			local prob = bot.Probability
			
			local Template = this.ProbTemplate:Clone()
			Template.LayoutOrder = i
			Template.BackgroundColor3 = Settings.Tiers[string.upper(RS.Assets.Bots[BotName].Settings.Rarity.Value)]["COLOR"]
			local BotModel = RS.Assets.Bots[BotName]:Clone()
			BotModel.Parent = Template.Display
			
			Utilities.UI.PointVPFToObject(BotModel, Template.Display)
			Template.Probability.Text = tostring(prob).."%"
			Template.Name = BotName
			Template.Parent = BillboardGui.ProbabilityFrame
		end
	end
end

InitProbabilityFrames()

function PopulateOpeningsFrame(result: table, Chest)
	for i, OpeningInfo in result do
		local BotName = OpeningInfo[1]
		local NewCopies = OpeningInfo[2]
		
		local BotFolder = Data.Bots:FindFirstChild(BotName)
		local isNew = NewCopies == 0
		local rarity = string.upper(RS.Assets.Bots[BotName].Settings.Rarity.Value)
		local tier = BotFolder:GetAttribute("Tier")
		
		local isMaxed = tier >= 10
		local req = isMaxed and 0 or Settings.Tiers[rarity]["REQ"][tier + 1]
		local progress = isMaxed and 0 or math.round(NewCopies/req*100)/100
		
		local Template = this.OpeningTemplate:Clone()
		Template.Name = BotName
		Template.Fields.BotName.Text = BotName
		Template.Fields.Rarity.Text = rarity
		Template.Fields.Rarity.TextColor3 = Settings.Tiers[rarity]["COLOR"]
		Template.BackgroundColor3 = Settings.Tiers[rarity]["COLOR"]
		Template.ProgressBar.Bar.Size = UDim2.fromScale(math.min(1, progress), 1)
		if progress >= 1 then
			Template.ProgressBar.Bar.BackgroundColor3 = Color3.fromRGB(0,255,0)
		end
		if isNew then
			Template.ProgressBar.Progress.Text = isNew and "New!"
			Template.ProgressBar.Progress.TextColor3 = isNew and Color3.new(0,255,0)
		elseif isMaxed then
			Template.ProgressBar.Progress.Text = tostring(NewCopies).."/MAX"
		else
			Template.ProgressBar.Progress.Text = tostring(NewCopies).."/"..tostring(req)
		end
		if i > RS.Chests[Chest.Name]:GetAttribute("Openings").Min then
			Template.Fields.Bonus.Visible = true
		end
		
		local BotModel = RS.Assets.Bots[BotName]:Clone()
		BotModel.Parent = Template.Display
		
		Utilities.UI.PointVPFToObject(BotModel, Template.Display)
		Template.Parent = UI.OpenChest.Openings.Frame.ScrollingFrame
	end
end

function ResetOpeningsFrame()
	for _, v in UI.OpenChest.Openings.Frame.ScrollingFrame:GetChildren() do
		if not v:IsA("Frame") then continue end
		if v.Name == "Done" or v.Name == "Buffer" then continue end
		v:Destroy()
	end
end

function ChestOpening(Chest: Instance, result: StringTable)
	UI.Canvas.Visible = false
	PopulateOpeningsFrame(result, Chest)
	UI.OpenChest.Chest.Visible = true
	
	local ChestModel = Chest.Model:Clone()
	ChestModel.Parent = UI.OpenChest.Chest.Tap.Display.WorldModel
	
	Utilities.UI.PointVPFToObject(ChestModel, UI.OpenChest.Chest.Tap.Display)
	
	local Spin = 0
	local Rotation = 0
	local base = ChestModel.PrimaryPart.CFrame
	
	local speed = 0.05
	
	local start = os.clock()
	
	local update = RunService.RenderStepped:Connect(function()
		local timePassed = os.clock()-start
		start = os.clock()
		if Spin > 0 then
			Rotation = math.clamp(Rotation + timePassed*2*speed, 0, 1)
			if Rotation == 1 then
				Rotation = 0
				Spin -= 1
			end
		else
			if Rotation ~= 0 then
				Rotation = math.clamp(Rotation + timePassed*2*speed, 0, 1)
			end
		end
		ChestModel:PivotTo(base * CFrame.Angles(0, math.rad(360)*Rotation, 0))
		speed = math.clamp(speed-timePassed*3, 0.25, 5)
	end)
	
	local tapConn
	tapConn = UI.OpenChest.Chest.Tap.Activated:Connect(function(InputObject, clickCount)
		Spin += 1
		speed = math.clamp(speed + 1, 1, 2.5)
		Utilities.Audio.PlayAudio("Hit")
		if clickCount < 5 then return end
		tapConn:Disconnect()
		update:Disconnect()
		ChestModel:Destroy()
		Utilities.Audio.PlayAudio("Tada")
		UI.OpenChest.Chest.Visible = false
		UI.OpenChest.Openings.Visible = true
		local doneConn
		UI.OpenChest.Openings.Size = UDim2.fromScale(0, 0)
		UI.OpenChest.Openings:TweenSize(UDim2.fromScale(0.7, 0.7),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Bounce,
			0.5
		)
		doneConn = UI.OpenChest.Openings.Frame.ScrollingFrame.Done.TextButton.Activated:Connect(function()
			doneConn:Disconnect()
			Utilities.Audio.PlayAudio("Click")
			UI.Canvas.Visible = true
			UI.OpenChest.Openings.Visible = false
			ResetOpeningsFrame()
			Remotes.ChestFinished:FireServer()
		end)
	end)
end

for _, Chest in workspace.Map.Chests:GetChildren() do
	if not Chest.Model:FindFirstChild("Main") then continue end
	local ProximityPrompt = Chest.Model.Main.ProximityPrompt
	ProximityPrompt.ActionText = "Open "..Chest.Name
	ProximityPrompt.ObjectText = Utilities.Short.en(RS.Chests[Chest.Name]:GetAttribute("Cost")).."¢"
	ProximityPrompt.Triggered:Connect(function()
		local result = Remotes.Chest:InvokeServer(RS.Chests[Chest.Name])
		if result ~= nil then
			ChestOpening(Chest, result)
			
		end
	end)
end
	

--// Shop
for _,Gamepass in RS.Gamepasses:GetChildren() do
	local NewGamepass = this.GamepassTemplate:Clone()

	local GamepassInfo

	local Succes, Error = pcall(function()
		GamepassInfo = MarketPlaceService:GetProductInfo(Gamepass.Value, Enum.InfoType.GamePass)
	end)

	if Error then 
		warn("An error as occured while gathering gamepass data: "..Error) 
		NewGamepass:Destroy() continue 
	else
		NewGamepass.Button.Center.ImageLabel.Image = "rbxassetid://"..(GamepassInfo.IconImageAssetId or 666669321)
		NewGamepass.Button.Center.Description.Text = GamepassInfo.Description 
		NewGamepass.Button.GPName.Text = GamepassInfo.Name
		
		local priceLabel = NewGamepass.Button.PriceLabel
		if Data.Gamepasses[Gamepass.Name].Value then
			priceLabel.Text = "Owned \u{E000}"
		else
			priceLabel.Text = "\u{E002}"..GamepassInfo.PriceInRobux
		end

		Data.Gamepasses[Gamepass.Name].Changed:Connect(function()
			if Data.Gamepasses[Gamepass.Name].Value then
				priceLabel.Text = "Owned \u{E000}"
			else
				priceLabel.Text = "\u{E002}"..GamepassInfo.PriceInRobux
			end
		end)

		NewGamepass.Button.MouseButton1Click:Connect(function()
			MarketPlaceService:PromptGamePassPurchase(player, Gamepass.Value)
			Utilities.Audio.PlayAudio("Click")
		end)

		NewGamepass.Parent = Frames.Shop.Gamepasses
	end
end

--// Slots
local SlotsFrame = Frames.Inventory.Slots
local slotSelected = nil

Remotes.UpdateBotList.OnClientEvent:Connect(function(Data)
	for botID, botMeta in pairs(Data) do
		if botMeta == -1 then
			local slot = SlotsFrame[tostring(botID)]
			slot.Fields.ObbyName.Text = "Obby: Unused"
			slot.Fields.Wins.Text = "Wins: 0"
			slot.Fields.Time.Text = "Time: 0.00"
		else
			local slot = SlotsFrame[tostring(botID)]
			slot.Fields.ObbyName.Text = "Obby: "..botMeta.ObbyName
			slot.Fields.Wins.Text = "Wins: "..tostring(botMeta.Wins)
			slot.Fields.Time.Text = "Time: "..tostring(botMeta.Time)
		end
	end
end)

--[[

function updateSlot(Child)
	local botID = tonumber(Child.Name)
	if botID == nil then warn("Invalid child: Not a valid BotID name") return end
	
	local botMeta = (Remotes.GetPlayerBotData:InvokeServer())[botID]
	if botMeta == nil then warn("Child not found in playerBots["..player.Name.."]") return end
	if botMeta == -1 then return end
	 
	local slot = SlotsFrame[Child.Name]
	slot.Fields.ObbyName.Text = "Obby: "..botMeta.ObbyName
	slot.Fields.Wins.Text = "Wins: "..tostring(botMeta.Wins) 
	slot.Fields.Time.Text = "Time: "..tostring(botMeta.Time)
end

function resetSlot(Child) -- when the player resets a bot slot
	local botID = tonumber(Child.Name)
	if botID == nil then warn("Invalid child: Not a valid BotID name") return end
	
	local botMeta = (Remotes.GetPlayerBotData:InvokeServer())[botID]
	if botMeta == nil then warn("Child not found in playerBots["..player.Name.."]") return end
	if botMeta ~= -1 then return end -- Bot is still in use

	local slot = SlotsFrame[Child.Name]
	slot.Fields.ObbyName.Text = "Obby: Unused"
	slot.Fields.Wins.Text = "Wins: 0"
	slot.Fields.Time.Text = "Time: 0.00"
end

WorkspaceBots.ChildAdded:Connect(updateSlot)
WorkspaceBots.ChildRemoved:Connect(resetSlot)
]]


function setSelectMode(isSelectMode, botID) -- when player selects a bot slot to be changed
	local targetFrame = isSelectMode and Frames.Inventory.Bots or SlotsFrame
	task.spawn(function() Utilities.UI.DisplaySection(targetFrame) end)
	Frames.Inventory.Buttons.Visible = not isSelectMode
	Frames.Inventory.SelectMode.Visible = isSelectMode
	Frames.Inventory.SelectMode.Heading.Text = botID and "Choose a bot for slot "..botID.."!" or ""
	--if isSelectMode and tutorialComplete == nil then
	--	if highlight then
	--		highlight:Destroy()
	--	end
	--	highlight = this:WaitForChild("Highlight"):Clone()
	--	highlight.Parent = Frames.Inventory.Bots.Starter
	--end
	slotSelected = botID and botID or nil
	for _, v in Frames.Inventory.Bots:GetChildren() do
		if not v:IsA("Frame") then continue end
		if not v:FindFirstChild("Select") then continue end
		v.Select.Interactable = isSelectMode
	end
end

for _, v in SlotsFrame:GetChildren() do -- Handles the buttons for each bot slot
	if not v:IsA("Frame") then continue end
	
	local botID = tonumber(v.Name)
	
	local CONFIRM_TIME = 2
	local lastClickTime = nil
	local thread = nil
	v.Fields.ResetButton.Activated:Connect(function()
		if not lastClickTime then
			lastClickTime = os.clock()
			v.Fields.ResetButton.Text = "Confirm?"
			if thread ~= nil then -- cancel existing thread if it exists
				task.cancel(thread)
				thread = nil
			end
			thread = task.spawn(function()
				task.wait(CONFIRM_TIME)
				v.Fields.ResetButton.Text = "RESET"
				lastClickTime = nil
			end)
			return
		end
		if os.clock() - lastClickTime < CONFIRM_TIME then
			Remotes.DeleteBot:FireServer(botID)
			v.Fields.ResetButton.Text = "RESET"
			lastClickTime =  nil
		end  
	end)

	v.Fields.Title.ChangeButton.Activated:Connect(function()
		setSelectMode(true, botID)
	end)
	
	Frames.Inventory.SelectMode.Cancel.Activated:Connect(function()
		setSelectMode(false)
	end)

	local locked = v:FindFirstChild("Locked")
	if locked == nil then continue end -- slot 1 stops here

	local buyButton = locked.BuyButton

	if botID == Settings["EXTRA_BOT_ID"] then
		local Gamepass = RS.Gamepasses.ExtraBot
		Remotes.SetOwnsBot:FireServer(4)
		Data.Gamepasses[Gamepass.Name].Changed:Connect(function()
			Remotes.SetOwnsBot:FireServer(4)
		end)
		buyButton.Activated:Connect(function()
			MarketPlaceService:PromptGamePassPurchase(player, Gamepass.Value)
		end)
		continue
	end -- slot 4 stops here

	buyButton.Activated:Connect(function() -- only slots 2 and 3
		local currentCredits = PlayerData.Credits.Value
		local cost = buyButton.Cost.Value
		if currentCredits < cost then return end
		Remotes.SetOwnsBot:FireServer(botID)
	end)
end

--// Bot Inventory
local BotInventory = {} -- all bots will be added in this table probably

local BotFrame = Frames.Inventory.Bots

function resetSlotSelection(slot)
	slot.Fields.Title.ChangeButton.Fields.BotName.Text = "None"
	slot.Fields.Title.ChangeButton.BackgroundColor3 = Settings.Tiers.NONE.COLOR
end

function UpdateFields(BotFolder: Folder)
	local template = BotFrame:FindFirstChild(BotFolder.Name)
	if not template then warn(BotFolder.Name.." template not found") return end
	
	local botSettings = RS.Assets.Bots[BotFolder.Name].Settings
	local rarity = string.upper(botSettings.Rarity.Value)
	local tier = BotFolder:GetAttribute("Tier")
	if tier < 1 or tier > 10 then warn("Tier out of range for "..BotFolder.Name) return end
	
	local isMaxed = tier >= 10
	local req = isMaxed and 0 or Settings.Tiers[rarity]["REQ"][tier + 1] -- +1 for the next tier
	local progress = isMaxed and 0 or math.round(BotFolder:GetAttribute("Copies") / req*100)/100
	
	template.Upgrade.ImageColor3 = (progress >= 1 and not isMaxed) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(180, 180, 180)
	template.Upgrade.Interactable = (progress >= 1 and not isMaxed) and true or false
	
	local fields = template.Fields
	template.Select.BackgroundColor3 = Settings.Tiers[rarity]["COLOR"]
	template.Display.BotName.Text = BotFolder.Name
	fields.Multiplier.Text = "Multiplier: x"..Utilities.Short.en(BotFolder:GetAttribute("Multiplier"))
	fields.Rarity.Text = rarity
	fields.Rarity.TextColor3 = Settings.Tiers[rarity]["COLOR"]
	fields.Tier.Text = "TIER "..tier
	fields.ProgressBar.Progress.Text = tostring(BotFolder:GetAttribute("Copies")).."/"..(isMaxed and "MAX" or tostring(req).." copies")
	fields.ProgressBar.Bar.Size = UDim2.fromScale(math.min(1,progress), 1)
	fields.ProgressBar.Bar.BackgroundColor3 = progress >= 1 and Color3.fromRGB(0,255,0) or Color3.fromRGB(102, 191, 255)
		
	local UnusedSlots = {1, 2, 3, 4}
	for _, v in pairs(Data.Bots:GetChildren()) do
		local slotEquipped = v:GetAttribute("SlotEquipped")
		if table.find(UnusedSlots, tonumber(slotEquipped)) then
			local slotEquipped = v:GetAttribute("SlotEquipped")
			local slot = SlotsFrame[slotEquipped]
			slot.Fields.Title.ChangeButton.Fields.BotName.Text = v.Name	
			local rarity = string.upper(RS.Assets.Bots[v.Name].Settings.Rarity.Value)
			slot.Fields.Title.ChangeButton.BackgroundColor3 = Settings.Tiers[rarity]["COLOR"]
			table.remove(UnusedSlots, table.find(UnusedSlots, slotEquipped))
		end
	end
	for _, x in pairs(UnusedSlots) do
		resetSlotSelection(SlotsFrame[tostring(x)])
	end
	--[[
	for _, v in SlotsFrame:GetChildren() do -- Delete bot from any other slot if it exists there
		if not v:IsA("Frame") or tonumber(v.Name) == nil then continue end
		if v.Fields.Title.ChangeButton.Fields.BotName.Text ~= BotFolder.Name then continue end
		resetSlotSelection(v)
	end
	]]
	
	

	
end

function AddBot(BotFolder) -- BotFolder is the bot's folder in Player.Data.Bots
	if not RS.Assets.Bots:FindFirstChild(BotFolder.Name) then warn(BotFolder.Name.." not found") return end
	task.wait(0.1)
	local template = this.BotTemplate:Clone()

	local BotModel = RS.Assets.Bots[BotFolder.Name]:Clone()
	BotModel.Parent = template.Display
	
	Utilities.UI.PointVPFToObject(BotModel, template.Display)
	template.Name = BotFolder.Name
	template.Parent = BotFrame
	
	UpdateFields(BotFolder)
	
	template.Upgrade.Activated:Connect(function()
		Remotes.UpgradeBot:FireServer(BotFolder)
		Utilities.Audio.PlayAudio("Click")
	end)
	
	template.Select.Activated:Connect(function()
		if slotSelected == nil then
			setSelectMode(false)
			warn("No slot was previously selected") 
			return
		end
		setSelectMode(false, slotSelected)
		Remotes.ChangeBot:FireServer(slotSelected, template.Name)
	end)
	
	for i, v in pairs(BotFolder:GetAttributes()) do
		BotFolder:GetAttributeChangedSignal(i):Connect(function()
			UpdateFields(BotFolder)
		end)
	end

	return template
end

for _, v in Data.Bots:GetChildren() do -- load bots on join
	coroutine.wrap(function()
		AddBot(v)
	end)()
end

local function OnBotAdded(Child) -- this function is ran when a bot is added, which adds a new bot ui instance
	AddBot(Child)
	--SortInventory()
end

local function OnBotRemoved(Child)
	if not BotFrame:FindFirstChild(Child.Name) then warn(Child.Name.." not found") return end
	BotFrame[Child.Name]:Destroy()
	if Child:GetAttribute("SlotEquipped") ~= -1 then
		resetSlotSelection(SlotsFrame[Child:GetAttribute("SlotEquipped")])
	end
	--SortInventory()
end

Data.Bots.ChildAdded:Connect(OnBotAdded)
Data.Bots.ChildRemoved:Connect(OnBotRemoved)



--// Obbies
function UpdateValidZones(Child)
	for _, v in workspace.Zones.ValidZones:GetChildren() do
		local obby = Data.Obbies:FindFirstChild(v.Name)
		local isOwned = obby ~= nil
		v.CanCollide = not isOwned
		v.SelectionBox.Color3 = isOwned and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
		v.SelectionBox.SurfaceTransparency = isOwned and 0.95 or 0.5
	end
end

UpdateValidZones()
Data.Obbies.ChildAdded:Connect(UpdateValidZones)
Data.Obbies.ChildRemoved:Connect(UpdateValidZones)

local ObbyToBuy = nil
for _, validZone in workspace.Zones.ValidZones:GetChildren() do
	validZone.Touched:Connect(function(hit)
		if game.Players:GetPlayerFromCharacter(hit.Parent) ~= player then return end
		if Data.Obbies:FindFirstChild(validZone.Name) then return end -- already owned
		if ObbyToBuy and Frames.ObbyPurchase.Visible then return end -- prompt already open
		Utilities.UI.DisplayFrame(Frames.ObbyPurchase, Frames.ObbyPurchase.OpenConfig, true)
		Frames.ObbyPurchase.Description.Text = "Would you like to purchase "..validZone.Name
			.." for "..Utilities.Short.en(RS.Assets.Obbies[validZone.Name]:GetAttribute("Cost")).."¢?"
		ObbyToBuy = validZone
	end)
end

Remotes.BuyObby:FireServer(workspace.Zones.ValidZones["Obby Lobby"])

Frames.ObbyPurchase.Yes.Activated:Connect(function()
	if not ObbyToBuy then return end
	Utilities.UI.DisplayFrame(Frames.ObbyPurchase, Frames.ObbyPurchase.CloseConfig, false)
	Remotes.BuyObby:FireServer(ObbyToBuy)
	ObbyToBuy = nil
end)

Frames.ObbyPurchase.No.Activated:Connect(function()
	Utilities.UI.DisplayFrame(Frames.ObbyPurchase, Frames.ObbyPurchase.CloseConfig, false)
	ObbyToBuy = nil
end)



--// Playback
local Playback = require(Modules:WaitForChild("Playback"))

BotReplay.OnClientEvent:Connect(function(Action, Player, BotID, Recording, Time, EquippedBot)
	if Action == "Play" then
		if EquippedBot then
			EquippedBot = EquippedBot.Name
		end
		Playback.Play(Player, BotID, Recording, Time, EquippedBot)
	elseif Action == "Stop" then
		Playback.Stop(Player, BotID)
	end
end)



--// Notifications
Remotes.SendNotification.OnClientEvent:Connect(function(text, sound)
	sound = sound or "Notification"
	local notificationTemplate = this.NotificationTemplate:Clone()
	notificationTemplate.Parent = UI.Canvas.Notifications
	notificationTemplate.TextLabel.Text = text
	Utilities.Audio.PlayAudio(sound)
	task.wait(5)
	notificationTemplate:Destroy()
end)



--// Tutorial
local tutorialComplete = player:FindFirstChild("TutorialCompleted")

local function promptSelectStarterBot()
	if not Buttons.InventoryButton:FindFirstChild("Spotlight") then
		this:WaitForChild("Spotlight"):Clone().Parent = Buttons.InventoryButton
	end
	Buttons.InventoryButton.Interactable = true
	Buttons.SettingsButton.Interactable = false
	Buttons.ShopButton.Interactable = false
	Buttons.SpectateButton.Interactable = false
	Frames.Inventory.Slots.ScrollingEnabled = false
	Frames.Inventory.Slots.CanvasPosition = Vector2.new(0,0)
	character.Humanoid.WalkSpeed = 0
	character.Humanoid.JumpPower = 0
	for _, v in Frames.Inventory.Buttons:GetChildren() do
		if not v:IsA("GuiButton") then continue end
		v.Interactable = false
	end
	Frames.Inventory.Slots["1"].Fields.ResetButton.Interactable = false
	if not Frames.Inventory.Slots["1"].Fields.Title.ChangeButton:FindFirstChild("Pulse") then
		this:WaitForChild("Pulse"):Clone().Parent = Frames.Inventory.Slots["1"].Fields.Title.ChangeButton
	end
	if not Frames.Inventory.Bots:WaitForChild("Starter"):FindFirstChild("Pulse") then
		this:WaitForChild("Pulse"):Clone().Parent = Frames.Inventory.Bots.Starter
	end
end

if PlayerData.Wins.Value > 0 then
	game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
	game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 1
	Buttons.Visible = true
	if not tutorialComplete then
		promptSelectStarterBot()
	end
end

PlayerData.Wins.Changed:Connect(function(value)
	if tutorialComplete or value <= 0 then return end
	Buttons.Visible = true
	promptSelectStarterBot()
end)

player.ChildAdded:Connect(function(c)
	if c.Name ~= "TutorialCompleted" then return end
	tutorialComplete = c
	Buttons.InventoryButton.Interactable = true
	Buttons.SettingsButton.Interactable = true
	Buttons.ShopButton.Interactable = true
	Buttons.SpectateButton.Interactable = true
	Frames.Inventory.Slots.ScrollingEnabled = true
	character.Humanoid.WalkSpeed = 16
	character.Humanoid.JumpPower = 50
	for _, v in Frames.Inventory.Buttons:GetChildren() do
		if not v:IsA("GuiButton") then continue end
		v.Interactable = true
	end
	Frames.Inventory.Slots["1"].Fields.ResetButton.Interactable = true
	if Frames.Inventory.Slots["1"].Fields.Title.ChangeButton:FindFirstChild("Pulse") then
		Frames.Inventory.Slots["1"].Fields.Title.ChangeButton.Pulse:Destroy()
	end
	if Frames.Inventory.Bots:WaitForChild("Starter"):FindFirstChild("Pulse") then
		Frames.Inventory.Bots.Starter.Pulse:Destroy()
	end
end)