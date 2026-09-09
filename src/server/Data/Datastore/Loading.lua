--// Configure

local LoadingFunctions = {}
local Values = require(script.Parent.Values)
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

--// Modules
local GS = RS["Game Settings"]
local Modules = RS.Modules
local botModule = require(SS.BotModule)
local Settings = require(GS.Settings)

--// Datastore
local PlayerData = DS:GetDataStore(Settings.DATASTORES.PLAYER_STORE)

local MPS = game:GetService("MarketplaceService")

local function CreateFolder(Player,FolderName)
	local NewFolder = Instance.new("Folder")
	NewFolder.Name = FolderName
	NewFolder.Parent = Player
	return NewFolder
end

--// Module

LoadingFunctions.LoadData = function(Player)
	local MainFolder = CreateFolder(Player,"Data")
	local Datastore

	local suc,er = pcall(function()
		Datastore = PlayerData:GetAsync(Player.UserId)
	end)

	if er then warn(er) Player:Kick("Failed to load. Make sure to allow API Services in studio & publish your games in order to make datastores work") return end

	if Datastore and Datastore.SessionId and game.JobId ~= Datastore.SessionId and os.time() - Datastore.LastInGame < 60 and not game:GetService("RunService"):IsStudio() then Player:Kick("Session Locked") end

	for _,FolderName in Values.Folders do
		if FolderName ~= "NonSaveValues" then
			CreateFolder(MainFolder,FolderName)
		else
			CreateFolder(Player,FolderName)
		end
	end

	--// Create all the non save values

	for _,Info in Values.NonSaveValues do
		local NewInstance = Instance.new(Info.Type)
		NewInstance.Name = Info.Name
		NewInstance.Value = Info.Value
		NewInstance.Parent = Player.NonSaveValues
	end

	--// Create all the save values

	for FolderName,FolderInfo in Values.SaveValues do	
		for _,Info in FolderInfo do
			local NewInstance = Instance.new(Info.Type)
			NewInstance.Name = Info.Name
			NewInstance.Value = Info.Value
			NewInstance.Parent = MainFolder[FolderName]
			
			

			if Datastore and Datastore[FolderName] then
				if Datastore[FolderName][Info.ID] ~= nil and Datastore[FolderName][Info.ID] ~= Info.Value then
					NewInstance.Value = Datastore[FolderName][Info.ID]
				end
			end
			
		end		
	end
	
	local playerData = Player.Data.PlayerData
	local botCapacity = Player.NonSaveValues.BotCapacity
	
	botModule.updateBotCapacity(Player)

	--// Check Gamepasses

	for _,Gamepass in MainFolder.Gamepasses:GetChildren() do
		if Gamepass.Value then continue end -- only check if you DONT have it
		
		if RS.Gamepasses:FindFirstChild(Gamepass.Name) == nil then continue end
		
		local GPId = RS.Gamepasses[Gamepass.Name].Value
		Gamepass.Value = MPS:UserOwnsGamePassAsync(Player.UserId, GPId)
	end

	--// Bots
	if Datastore and Datastore.Bots then
		for name, botInfo in Datastore.Bots do
			local clone = RS.Assets.BotTemplate:Clone()
			clone.Name = name
			clone:SetAttribute("Tier", botInfo.Tier)
			clone:SetAttribute("SlotEquipped", botInfo.SlotEquipped)
			clone:SetAttribute("Copies", botInfo.Copies)
			clone:SetAttribute("Multiplier", RS.Assets.Bots[name].Settings.BaseMultiplier.Value  * Settings.Tiers.TIER_MULTIPLIER^(botInfo.Tier-1))
			clone.Parent = Player.Data.Bots
		end
	end
	
	--// Obbies
	if Datastore and Datastore.Obbies then
		for name, obbyInfo in Datastore.Obbies do
			local clone = RS.Assets.Obbies[name]:Clone()
			clone:SetAttribute("PR", obbyInfo.PR)
			clone.Parent = Player.Data.Obbies
		end
	end
	
	if Datastore and Datastore.Tutorial then -- If exists, create value to mark tutorial completion
		local tutorialCompleted = Instance.new("BoolValue")
		tutorialCompleted.Name = "TutorialCompleted"
		tutorialCompleted.Parent = Player
	end

end

return LoadingFunctions
