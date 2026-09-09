-- created 11/??/2025
-- updated 11/21/2025

local botModule = {}

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Remotes
local Remotes = RS.Remotes
local UpdateBotList = Remotes.UpdateBotList
local BotReplay = Remotes.BotReplay

--// Modules
local GS = RS["Game Settings"]
local Settings = require(GS.Settings)

--// Variables
botModule.playerBots = {}
local playerNumBots = {}
local botIDStop = {}

--// Private Functions

--[[
    This method disables all joints of a given rig. Additionally, it sets
    the rig's transparency to 0.5.
    @param rig - The rig model.
]]
function disableJoints(rig)
	for _, v in pairs(rig:GetDescendants()) do
		if v:IsA("JointInstance") then
			if v.Part0.Parent ~= rig or v.Part1.Parent ~= rig then continue end
			v.Enabled = false
		elseif v:IsA("BasePart") and v.Parent == rig then
			v.Anchored = true
			v.CanCollide = false
			if v.Name ~= "HumanoidRootPart" then v.Transparency = 0.5 end
		end
	end
end

--[[
    This method updates the player's wins per second value in PlayerData.
    @param player - The player instance.
]]
function updateWPS(player)
	local wps = botModule.calculateWPS(player)
	player.Data.PlayerData.WPS.Value = wps
end

--// Public Functions

--[[
    This constructor initializes the player's bot data.
    @param player - The player instance.
]]
function botModule.initializeData(player)
	botModule.playerBots[player] = {-1, -1, -1, -1}
	botIDStop[player] = nil
end

--[[
    This method updates the player's bot capacity based on the total
    number of bots they own.
    @param player - The player instance.
]]
function botModule.updateBotCapacity(player)
	local playerData = player.Data.PlayerData
	local botCapacity = player.NonSaveValues.BotCapacity
	botCapacity.Value = 1
	if playerData.OwnsBot2.Value then botCapacity.Value += 1 end
	if playerData.OwnsBot3.Value then botCapacity.Value += 1 end
	if playerData.OwnsBot4.Value then botCapacity.Value += 1 end
end

--[[
    This function calculates the number of bots in use by the player. 
    @param player - The player instance.
    @return The number of active bots the player has.
]]
function botModule.countSlotsUsed(player)
	local numBots = 0
	for _, v in pairs(botModule.playerBots[player]) do
		if v and v ~= -1 then numBots += 1 end
	end
	return numBots
end

--[[
    This function finds the bot ID of the slowest bot. If no bot was slower
    than the player's time, it returns nil.
    @param player - The player instance.
    @param elapsed - The player's elapsed time.
    @param matchingBots - The bots that match the player's currentObby.
    @return The slowest bot ID or nil.
]]
function botModule.findSlowestBotID(player, elapsed, matchingBots)
	local slowestBotID
	local slowestTime = 0
	for _, botID in pairs(matchingBots) do
		local bot = botModule.playerBots[player][botID]
		if (bot.Time > slowestTime) then
			slowestBotID = botID
			slowestTime = bot.Time
		end
	end
	if slowestTime > elapsed then
		return slowestBotID
	end
	return nil
end

--[[
    This function finds the first available or slowest bot ID to override.
    If no bot can be overriden, it returns nil.
    @param player - The player instance.
    @param elapsed - The player's elapsed time.
    @return The bot ID to override or nil.
]]
function botModule.findBotIDtoOverride(player, elapsed)
	local playerData = player.Data.PlayerData
	local nonSaveValues = player.NonSaveValues
	local botCapacity = player.NonSaveValues.BotCapacity
	local currentObby = nonSaveValues.CurrentObby
	
	local bot1 = botModule.playerBots[player][1]
	local bot2 = botModule.playerBots[player][2]
	local bot3 = botModule.playerBots[player][3]
	local bot4 = botModule.playerBots[player][4]
	
	-- Return first available bot
	if bot1 == -1 then return 1 end
	if bot2 == -1 and playerData.OwnsBot2.Value then return 2 end
	if bot3 == -1 and playerData.OwnsBot3.Value then return 3 end
	if bot4 == -1 and playerData.OwnsBot4.Value then return 4 end
	
	-- If no available bot, check if any active bot has matching ObbyName
	local matchingBots = {}
	if bot1 ~= -1 and bot1.ObbyName == currentObby.Value then matchingBots[1] = 1 end
	if bot2 ~= -1 and bot2.ObbyName == currentObby.Value then matchingBots[2] = 2 end
	if bot3 ~= -1 and bot3.ObbyName == currentObby.Value then matchingBots[3] = 3 end
	if bot4 ~= -1 and bot4.ObbyName == currentObby.Value then matchingBots[4] = 4 end
	
	if next(matchingBots) == nil then
		print("No matching bots available for: "..currentObby.Value)
		return nil
	end
	
	-- Of all bots with matching ObbyName, return slowest bot
	return botModule.findSlowestBotID(player, elapsed, matchingBots)
end

--[[
    This method creates the bot data for the player and starts the bot replay.
    @param player - The player instance.
	@param botID - The bot ID.
    @param elapsed - The player's elapsed time.
    @param recording - The bot's recording.
    @param obby - The name of the current obby.
]]

function botModule.updateList(player)
	local data = {}
	for botID, botMeta in pairs(botModule.playerBots[player]) do
		if botMeta == -1 then
			data[botID] = -1
		else
			data[botID] = {
				Time = botMeta.Time;
				ObbyName = botMeta.ObbyName;
				Wins = botMeta.Wins;
			}
		end
	end
	UpdateBotList:FireClient(player, data)
end

function botModule.createBot(player, botID, elapsed, recording, obby, wins)
	elapsed = math.round(elapsed*100)/100
	local newBot = {
		Time = elapsed;
		Recording = recording;
		ObbyName = obby;
		Wins = wins or 0;
	}
	botModule.playerBots[player][botID] = newBot
	--UpdateBotList:FireClient(player, newBot, botID)
	
	local equippedBot = shared.GetEquippedBot(player, botID)
	botModule.updateList(player)
	player.NonSaveValues.NumOfSlotsUsed.Value = botModule.countSlotsUsed(player)
	
	if equippedBot then
		botModule.playerBots[player][botID].Start = tick()
		newBot.Multiplier = equippedBot:GetAttribute("Multiplier")
		BotReplay:FireAllClients("Play", player, botID, newBot.Recording, newBot.Time, equippedBot)
	else
		newBot.Multiplier = nil
		print(tostring(botID).." has no bot equipped!")
		return
	end
end

--[[
    This method removes the bot data for the player and stops the bot replay.
    @param player - The player instance.
    @param botID - The bot ID.
]]
function botModule.removeBotData(player, botID)
	if botID < 1 or botID > 4 then
		warn(botID.." is out of bounds")
		return
	end
	if botModule.playerBots[player][botID] == -1 then return end
	botModule.playerBots[player][botID] = -1
	BotReplay:FireAllClients("Stop", player, botID)
	updateWPS(player)
	--UpdateBotList:FireClient(player, botModule.playerBots[player][botID], botID)
	player.NonSaveValues.NumOfSlotsUsed.Value = botModule.countSlotsUsed(player)
	botModule.updateList(player)
end

--[[
	This function gives us access to useful instances like
	player.Data.Bots[botName] and Inventory.Bots[botName]
	@param player - The player instance.
	@param slotEquipped - The slot equipped (same as botID).
]]
function botModule.getBotNameFromSlot(player, slotEquipped) 
	for _, v in player.Data.Bots:GetChildren() do
		if v:GetAttribute("SlotEquipped") == slotEquipped then return v.Name end
	end
	warn("This slot is unused")
	return nil
end

--[[
	Given a valid bot name, this function returns the matching bot folder
	inside RS.Assets.Bots.
	@param BotName - The bot's name.
	@return The bot folder in RS.Assets.Bots.
]]
function botModule.FindBotFromBotName(BotName)
	for _, Bot in RS.Assets.Bots:GetChildren() do
		if string.lower(Bot.Name) == BotName then
			return Bot
		end
	end
	return nil
end

--[[
	Given a valid bot folder in RS.Assets.Bots, this function returns the matching
	bot folder inside player.Data.Bots.
	@param player - The player instance.
	@param Bot - The bot folder in RS.Assets.Bots.
	@return The bot folder in player.Data.Bots.
]]
function botModule.FindBotFolder(player, Bot)
	for _, BotFolder in player.Data.Bots:GetChildren() do
		if BotFolder.Name == Bot.Name then
			return BotFolder
		end
	end
	return nil
end

--[[
	This function creates and returns a new bot folder inside player.Data.Bots.
	@param player - The player instance.
	@param Bot - The bot folder in RS.Assets.Bots.
	@return The new bot folder in player.Data.Bots.
]]
function botModule.CreateNewBotFolder(player, Bot)
	local NewBotFolder = RS.Assets.BotTemplate:Clone()
	NewBotFolder.Name = Bot.Name
	NewBotFolder:SetAttribute("Tier", 1)
	NewBotFolder:SetAttribute("Copies", 0)
	NewBotFolder:SetAttribute("Multiplier", Bot.Settings.BaseMultiplier.Value)
	NewBotFolder:SetAttribute("SlotEquipped", -1)
	NewBotFolder.Parent = player.Data.Bots
	return NewBotFolder
end

--[[
    This function calculates the credits multiplier based on obby and
    completion time.
    @param obbyName - The name of the obby.
    @param elapsed - The completion time of the player/replay.
    @return The multiplier.
]]
function botModule.calculateMultiplier(obbyName, elapsed)
	local multFunction = 100^(-(elapsed - RS.Assets.Obbies[obbyName]:GetAttribute("ProTime"))) + 1
	local multiplier = math.min(3, multFunction)
	return multiplier
end

--[[
    This function increments the player's Wins and the bot's Wins by 1. It also
    increases the player's Credits value.
    @param player - The player instance.
    @param botID - The bot ID.
]]
function botModule.incrementStats(player, obbyName, elapsed, botID, botMultiplier)
	botMultiplier = botMultiplier or 1 -- 1 if it's the player who completed the obby
	local playerData = player.Data.PlayerData
	playerData.Wins.Value += 1
	local multiplier = botModule.calculateMultiplier(obbyName, elapsed)
	local creditsToAward = math.round(RS.Assets.Obbies[obbyName]:GetAttribute("Prize") * multiplier * botMultiplier)
	playerData.Credits.Value += creditsToAward
	if botID == nil then return end
	botModule.playerBots[player][botID].Wins += 1
	botModule.updateList(player)
end

--[[
    This function calculates the wins per second value of the player.
    @param player - The player instance.
    @return The wins per second of the player.
]]
function botModule.calculateWPS(player)
	local bot1WPS = 0
	if botModule.playerBots[player][1] ~= -1 then
		bot1WPS = 1/botModule.playerBots[player][1].Time
	end

	local bot2WPS = 0
	if botModule.playerBots[player][2] ~= -1 then
		bot2WPS = 1/botModule.playerBots[player][2].Time
	end

	local bot3WPS = 0
	if botModule.playerBots[player][3] ~= -1 then
		bot3WPS = 1/botModule.playerBots[player][3].Time
	end

	local wps = bot1WPS + bot2WPS + bot3WPS
	-- Round to 2 decimals
	wps = math.floor(wps * 100) / 100
	return wps
end

--[[
	This function returns whether the player's bot slots have no recordings
	@param player - The player instance.
	@return true if the player's bot slots have no recordings, false otherwise.
]]
function botModule.isSlotsEmpty(player)
	if botModule.playerBots[player][1] ~= -1 then return false end
	if botModule.playerBots[player][2] ~= -1 then return false end
	if botModule.playerBots[player][3] ~= -1 then return false end
	if botModule.playerBots[player][4] ~= -1 then return false end
	return true
end

return botModule