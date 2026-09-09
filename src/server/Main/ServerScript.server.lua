-- created 11/12/2025
-- updated 11/21/2025

--// Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local botModule = require(SS.BotModule)
local Settings = require(RS:WaitForChild("Game Settings").Settings)

--// Remotes
local Remotes = RS:WaitForChild("Remotes")
local FindBotIDToOverride = Remotes.FindBotIDToOverride
local SetOwnsBot = Remotes.SetOwnsBot
local BotReplay = Remotes.BotReplay

--// Main
for _, v in pairs(workspace.Zones.ValidZones:GetChildren()) do
	if not (v:IsA("BasePart") and RS.Assets.Obbies:FindFirstChild(v.Name) and v:FindFirstChild("DescriptionGui") and v.DescriptionGui:FindFirstChild("Description")) then continue end
	local description = v.DescriptionGui.Description
	description.ObbyName.Text = v.Name
	description.Prize.Text = RS.Assets.Obbies[v.Name]:GetAttribute("Prize").."¢ per win"
	if RS.Assets.Obbies[v.Name]:GetAttribute("Cost") == 0 then
		description.Cost.Text = "FREE"
	else
		description.Cost.Text = "Buy: "..RS.Assets.Obbies[v.Name]:GetAttribute("Cost").."¢"
	end
end

--// Server Events
Remotes.GetPlayerBotMeta.OnServerInvoke = function(player)
	local data = botModule.playerBots[player]   -- could be nil
	return data and table.clone(data) or {}
end

FindBotIDToOverride.OnServerInvoke = function(player, elapsed)
	return botModule.findBotIDtoOverride(player, 0)
end

-- TODO: change to remote function
SetOwnsBot.OnServerEvent:Connect(function(player, botID)
	if botID <= Settings["MIN_BOT_ID"] or botID > Settings["EXTRA_BOT_ID"] then
		warn("botID = "..tostring(botID).." is out of range")
		return
	end
	
	local data = player.Data
	local Gamepass = RS.Gamepasses.ExtraBot
	local ownsBot = data.PlayerData["OwnsBot"..tostring(botID)]
	
	if botID == Settings["EXTRA_BOT_ID"] then
		if data.Gamepasses[Gamepass.Name].Value or table.find(Settings["GAMEPASS_WHITELIST"]["EXTRA_BOT"], player.UserId) then
			ownsBot.Value = true
		else
			ownsBot.Value = false
		end
	else
		local credits = data.PlayerData.Credits
		local cost = Settings["BOT SLOTS"][botID]
		if credits.Value < cost then return end
		credits.Value -= cost
		ownsBot.Value = true
	end
	
	botModule.updateBotCapacity(player)
	
	 -- TODO: return true -> run lines below on a localscript
	local botFrame = player.PlayerGui.UI.Canvas.Frames.Inventory.Slots[tostring(botID)]
	local locked = botFrame.Locked
	locked.Visible = not ownsBot.Value
	botFrame.Fields.Interactable = ownsBot.Value
	botFrame.Fields.ResetButton.Visible = ownsBot.Value
end)

Remotes.UpgradeBot.OnServerEvent:Connect(function(player, BotFolder)
	if not BotFolder then warn("BotFolder not provided") return end
	
	local tier, isMaxed = BotFolder:GetAttribute("Tier"), BotFolder:GetAttribute("Tier") >= 10
	if isMaxed then warn("Bot maxed") return end
	
	local rarity = string.upper(RS.Assets.Bots[BotFolder.Name].Settings.Rarity.Value)
	local req = (isMaxed and 0) or Settings.Tiers[rarity]["REQ"][tier + 1]
	if BotFolder:GetAttribute("Copies") < req then warn("Not enough copies") return end
	
	BotFolder:SetAttribute("Tier", BotFolder:GetAttribute("Tier") + 1)
	BotFolder:SetAttribute("Copies", BotFolder:GetAttribute("Copies") - req)
	BotFolder:SetAttribute("Multiplier", RS.Assets.Bots[BotFolder.Name].Settings.BaseMultiplier.Value  * Settings.Tiers.TIER_MULTIPLIER^(BotFolder:GetAttribute("Tier")-1))
end)

Remotes.ChangeBot.OnServerEvent:Connect(function(player, botID, botName)
	if not botID or not botName then warn("Invalid arguments") return end
	if botID < Settings["MIN_BOT_ID"] or botID > Settings["EXTRA_BOT_ID"] then warn("botID = "..tostring(botID).." is out of range") return end
	
	local data = player.Data
	local bot = data.Bots:FindFirstChild(botName)
	if not bot then warn(botName.." not found in "..player.Name.."'s Data.Bots Folder") return end
	
	-- check if player already has bot equipped in that slot
	for _, v in data.Bots:GetChildren() do
		if v:GetAttribute("SlotEquipped") == botID then
			v:SetAttribute("SlotEquipped", -1)
			if botModule.playerBots[player][botID] ~= -1 and botModule.playerBots[player][botID].Start then
				botModule.playerBots[player][botID].Start = nil
				BotReplay:FireAllClients("Stop", player, botID)
			end
			break
		end
	end
	if botName == "Starter" and player:FindFirstChild("TutorialCompleted") == nil then
		local tutorialCompleted = Instance.new("BoolValue")
		tutorialCompleted.Name = "TutorialCompleted"
		tutorialCompleted.Parent = player
	end
 	bot:SetAttribute("SlotEquipped", botID)
	if botModule.playerBots[player][botID] ~= -1 then
		if botModule.playerBots[player][botID].Start then
			BotReplay:FireAllClients("Stop", player, botID)
		end
		local equippedBot = shared.GetEquippedBot(player, botID)
		if equippedBot then
			botModule.playerBots[player][botID].Start = tick()
			botModule.playerBots[player][botID].Multiplier = equippedBot:GetAttribute("Multiplier")
			BotReplay:FireAllClients("Play", player, botID, botModule.playerBots[player][botID].Recording, botModule.playerBots[player][botID].Time, equippedBot)
		else
			botModule.playerBots[player][botID].Multiplier = nil
		end
	end
end)

function ChooseRandomBot(Chest, LuckMultiplier)
	local Bots, TotalWeight = {}, 0

	for key, Probability in Chest.Probabilities:GetAttributes() do
		local BotName = (string.gsub(key, "_", " "))
		table.insert(Bots, {BotName, Probability})
	end

	table.sort(Bots, function(a,b) -- sort by probability (highest probability -> 1st index)
		return a[2] > b[2]
	end)

	local BaseChance = Bots[1][2] -- this is the most common bot's probability

	for _, v in Bots do -- calculate total weight and adjust bot weights according to LuckMultiplier
		local Chance = math.min(v[2] * LuckMultiplier, BaseChance) -- increases the odds of rarer bots
		TotalWeight += Chance
		v[2] = Chance
	end

	local Chance = Random.new():NextNumber(0,TotalWeight) -- pick a number from 0 to TotalWeight - 1
	local Counter = 0
	for _, v in Bots do -- loop from the easiest to the rarest bot
		-- say Chance is 50 and the easiest bot is 60. 
		Counter += v[2] -- Counter now is 60
		if Counter >= Chance then -- since Counter >= Chance we return the easiest bot
			return v[1]
		end -- else, repeat the process with the next easiest bot
	end
end

Remotes.Chest.OnServerInvoke = function(Player, Chest)
	if Player.NonSaveValues.IsOpeningChest.Value then return end

	if not Chest then warn(Chest.." does not exist") return end
	if Chest:FindFirstChild("ProductId") then return end -- robux chest

	if Player.Data.PlayerData.Credits.Value >= Chest:GetAttribute("Cost") then
		Player.Data.PlayerData.Credits.Value -= Chest:GetAttribute("Cost")
		Player.NonSaveValues.IsOpeningChest.Value = true
		
		local Results = {}

		local LuckMultiplier = (Player.Data.Gamepasses.Lucky.Value or table.find(Settings["GAMEPASS_WHITELIST"]["LUCKY"], Player.UserId)) and Settings["LUCK_MULTIPLIER"] or 1
		
		local Chance = Random.new():NextNumber(0, 100) -- 25% chance to receive a bonus opening
		local Amount = Chance >= 25 and Chest:GetAttribute("Openings").Min or Chest:GetAttribute("Openings").Max 

		for i = 1, Amount do
			local BotName = ChooseRandomBot(Chest, LuckMultiplier) 
			
			local BotFolder = botModule.FindBotFolder(Player, RS.Assets.Bots[BotName])
			local NewCopies = BotFolder and BotFolder:GetAttribute("Copies") + 1 or 0 -- number of copies after this iteration
			if BotFolder then -- add on to the pre-existing folder
				BotFolder:SetAttribute("Copies", BotFolder:GetAttribute("Copies") + 1)
			else -- initialize a new folder
				BotFolder = game.ReplicatedStorage.Assets.BotTemplate:Clone()
				BotFolder.Name = BotName
				BotFolder.Parent = Player.Data.Bots
				BotFolder:SetAttribute("Multiplier", RS.Assets.Bots[BotName].Settings.BaseMultiplier.Value)
			end
			Results[i] = {BotName, NewCopies}
		end
		return Results
	end
end

Remotes.ChestFinished.OnServerEvent:Connect(function(player)
	player.NonSaveValues.IsOpeningChest.Value = false
end)

Remotes.BuyObby.OnServerEvent:Connect(function(player, validZone)
	if player.Data.Obbies:FindFirstChild(validZone.Name) then print("already owned") return end -- already owned
 
	local obby = RS.Assets.Obbies[validZone.Name]
	if player.Data.PlayerData.Credits.Value < obby:GetAttribute("Cost") then print("not enough credits") return end
	player.Data.PlayerData.Credits.Value -= obby:GetAttribute("Cost")
	
	local clone = obby:Clone()
	clone.Parent = player.Data.Obbies
end)

shared.GetEquippedBot = function(Player, botID)
	local Data = Player:FindFirstChild("Data")
	if Data then
		local Bots = Data:FindFirstChild("Bots")
		if Bots then
			for _, bot in Bots:GetChildren() do
				if bot:GetAttribute("SlotEquipped") == botID then
					return bot
				end
			end
		end
	end
	return nil
end
