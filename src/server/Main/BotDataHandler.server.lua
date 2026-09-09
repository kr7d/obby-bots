-- created 11/??/25
-- updated 11/20/25

--// Services
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local DSS = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")


--// Modules
local Modules = RS.Modules
local botModule = require(SS.BotModule)
local Settings = require(RS["Game Settings"].Settings)
local Utilities = require(Modules.Utilities)

--// Datastore
local botStore = DSS:GetDataStore(Settings.DATASTORES.BOT_STORE)

--// Remotes
local Remotes = RS.Remotes
local SetCurrentObby = Remotes.SetCurrentObby
local DeleteBot = Remotes.DeleteBot
local SetBotCap = Remotes.SetBotCap
local UpdateBotList = Remotes.UpdateBotList
local BotReplay = Remotes.BotReplay

--// Variables
--local allPlayerData = {}
local isStudio = RunService:IsStudio()

--// Functions
function cframeToTable(cf: CFrame) return {cf:GetComponents()} end

function tableToCframe(t: table) return CFrame.new(table.unpack(t)) end

function initializePlayer(player)
	local botFolder = Instance.new("Folder")
	botFolder.Name = player.Name
	botFolder.Parent = game.Workspace.Bots
	botModule.initializeData(player)
end

function initializeBots(player, botData)
	for botID, botMeta in pairs(botData) do
		if botMeta == -1 then continue end
		local Models = botModule.createBot(player, botID, botMeta.Time, botMeta.Recording, botMeta.ObbyName, botMeta.Wins)
	end
end

function loadData(player)

	local botSuccess, botData = pcall(function()
		return botStore:GetAsync(player.UserId)
	end)

	if botSuccess and botData then
		for botID = 1, Settings["MAX_BOT_SLOT"] do
			if botData[botID] ~= -1 then
				--print(botData[botID])
				botData[botID].Recording.Initial = tableToCframe(botData[botID].Recording.Initial)

				for i = 1, botData[botID].Recording.Frames do
					botData[botID].Recording.Sequence[i] = tableToCframe(botData[botID].Recording.Sequence[i])
				end
			end
		end
		print("LOADED BOT DATA")
		print(botData)
		initializeBots(player, botData)
	elseif botSuccess then
		botData = {-1, -1, -1, -1}
		initializeBots(player, botData)
	else
		local DontSaveTag = Instance.new("BoolValue")
		DontSaveTag.Name = "DontSave"
		DontSaveTag.Parnet = player
		player:Kick("Error: Failed to retrieve data")
		print("Failed to retrieve bot data for "..player.Name)
	end

end

function saveData(player)
	if player:FindFirstChild("DontSave") then return end
	local playerBotMeta = botModule.playerBots[player]

	local botMeta = {}

	for botID = 1, Settings["MAX_BOT_SLOT"], 1 do
		if playerBotMeta[botID] ~= -1 then
			botMeta[botID] = {}
			botMeta[botID].Time = playerBotMeta[botID].Time
			botMeta[botID].Wins = playerBotMeta[botID].Wins
			botMeta[botID].ObbyName = playerBotMeta[botID].ObbyName
			botMeta[botID].Recording = {
				Walking = playerBotMeta[botID].Recording.Walking;
				Actions = playerBotMeta[botID].Recording.Actions;
				Climbing = playerBotMeta[botID].Recording.Climbing;
				Frames = playerBotMeta[botID].Recording.Frames;
				Initial = cframeToTable(playerBotMeta[botID].Recording.Initial);
				Sequence = {};
			}
			for i = 1, botMeta[botID].Recording.Frames, 1 do
				botMeta[botID].Recording.Sequence[i] = cframeToTable(playerBotMeta[botID].Recording.Sequence[i])
			end
		else
			botMeta[botID] = -1
		end
	end

	for i = 1, Settings["MAX_BOT_SLOT"], 1 do
		botModule.removeBotData(player, i)
	end
	
	botModule.playerBots[player] = nil

	local success, errorMessage = pcall(function()
		botStore:SetAsync(player.UserId, botMeta)
	end)
	
	if success then
		warn("SAVED BOT DATA")
		print(botMeta)
	else
		print("FAILED TO SAVE DATA")
		print(errorMessage)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	initializePlayer(player)
	player:WaitForChild("Loaded")
	loadData(player)
	-- create starter bot for a new player
	local Bot = botModule.FindBotFromBotName("starter")
	local BotFolder = botModule.FindBotFolder(player, Bot)
	if BotFolder then return end -- check if player already has the Starter bot
	botModule.CreateNewBotFolder(player, Bot)
end)

game.Players.PlayerRemoving:Connect(function(player)
	saveData(player)
end)

--// Server Events
SetCurrentObby.OnServerEvent:Connect(function(player, obbyName: String)
	if obbyName == "NONE" then
		player.NonSaveValues.CurrentObby.Value = "NONE"
		return
	end
	if not player.Data.Obbies:FindFirstChild(obbyName) then -- obby not owned
		player.NonSaveValues.CurrentObby.Value = "NONE"
		return
	end
	player.NonSaveValues.CurrentObby.Value = obbyName
end)

DeleteBot.OnServerEvent:Connect(function(player, botID)
	botModule.removeBotData(player, botID)
end)

SetBotCap.OnServerEvent:Connect(function(player, value)
	if value >= Settings["MAX_BOT_SLOT"] then return end
	player.NonSaveValues.BotCapacity.Value = value
end)

RunService.Heartbeat:Connect(function()
	for player, bots in pairs(botModule.playerBots) do
		for botId, botMeta in pairs(bots) do
			if botMeta ~= -1 and botMeta.Start ~= nil then
				local timeElapsed = tick()-botMeta.Start
				if timeElapsed >= botMeta.Time then
					botModule.incrementStats(player, botMeta.ObbyName, botMeta.Time, botId, botMeta.Multiplier)
					local equippedBot = shared.GetEquippedBot(player, botId)
					if equippedBot then
						botMeta.Start = tick()
						botMeta.Multiplier = equippedBot:GetAttribute("Multiplier")
						BotReplay:FireAllClients("Play", player, botId, botMeta.Recording, botMeta.Time, equippedBot)
					else
						botMeta.Start = nil
						botMeta.Multiplier = nil
					end
					--UpdateBotList:FireClient(player, botMeta, botId)
				end
			end
		end
	end
end)
