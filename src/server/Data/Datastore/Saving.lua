local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")

local Settings = require(RS["Game Settings"].Settings)

local SavingFunctions = {}

SavingFunctions.SaveData = function(Player, AutoSave)
	local Folder = Player.Data
		
	if Player:FindFirstChild("Loaded") == nil or Player.Loaded.Value == false then
		return
	end
	
	Player.Loaded.Value = false
	
	local Save = {}
	
	if Player:FindFirstChild("TutorialCompleted") then
		Save.Tutorial = true
	end
		
	for FolderName,FolderInfo in require(script.Parent.Values).SaveValues do
		Save[FolderName] = {}
		
		for _,Info in FolderInfo do
			Save[FolderName][Info.ID] = Folder[FolderName][Info.Name].Value
		end
	end
	
	Save["Bots"] = {}
	for _,Bot in Folder.Bots:GetChildren() do
		if not RS.Assets.Bots:FindFirstChild(Bot.Name) then warn(Bot.Name.." not found -> not saving") continue end
		Save["Bots"][Bot.Name] = {
			Tier = Bot:GetAttribute("Tier"),
			SlotEquipped = Bot:GetAttribute("SlotEquipped"),
			Copies = Bot:GetAttribute("Copies"),
			Multiplier = Bot:GetAttribute("Multiplier"),
		}
	end
	
	Save["Obbies"] = {}
	for _,Obby in Folder.Obbies:GetChildren() do
		if not RS.Assets.Obbies:FindFirstChild(Obby.Name) then warn(Obby.Name.." not found -> not saving") continue end
		Save["Obbies"][Obby.Name] = {
			PR = Obby:GetAttribute("PR")
		}
	end
	
	if AutoSave then
		Save.SessionId = game.JobId
		Save.LastInGame = os.time()
	end
	
	local suc,er = pcall(function()
		DS:GetDataStore(Settings.DATASTORES.PLAYER_STORE):SetAsync(Player.UserId, Save)
	end)
	
	if er then warn("error with saving data for "..Player.Name.." : "..er) end
end

return SavingFunctions