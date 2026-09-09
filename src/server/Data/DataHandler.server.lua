--// Services

local Players = game:GetService("Players")

--// Server Modules

local MainFolder = script.Parent
local Datastore = require(MainFolder.Datastore)
local Values = require(MainFolder.Datastore.Values)

if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then return end

--// Player Join

local playerRigs = game.ReplicatedStorage.Modules.Playback.PlayerRigs

Players.PlayerAdded:Connect(function(plr)
	task.spawn(function()
		local description = Players:GetHumanoidDescriptionFromUserId(plr.UserId, Enum.HumanoidRigType.R6)
		description.Parent = workspace
		local clone = playerRigs.Parent.PlaybackRig:Clone()
		clone.Parent = playerRigs
		clone.Name = plr.Name
		task.wait(2)
		if clone:FindFirstChild("Humanoid") then clone.Humanoid:ApplyDescription(description) end
	end)
	Datastore.LoadData(plr)
	
	task.wait(1)
	warn("LOADING COMPLETE")
	local Loaded = Instance.new("BoolValue")
	Loaded.Name = "Loaded"
	Loaded.Value = true
	Loaded.Parent = plr
	
end)

--// Save data when a player leaves
Players.PlayerRemoving:Connect(function(plr)
	if playerRigs:FindFirstChild(plr.Name) then
		playerRigs[plr.Name]:Destroy()
	end
	Datastore.SaveData(plr)
end)

--// Save data when the server closes
game:BindToClose(function()
	task.wait(2) -- Bt: this seems to fix botStore:SetAsync(player.UserId, botMeta) in BotDataHandler
	for _,v in Players:GetPlayers() do
		Datastore.SaveData(v)
	end
end)

--// Autosave
local AutoSaveTime = 240

while task.wait(AutoSaveTime) do
	for _, plr in (Players:GetChildren()) do
		if not plr:FindFirstChild("Loaded") or not plr.Loaded.Value then continue end

		pcall(function()
			Datastore.SaveData(plr, true)
		end)
		
		plr.Loaded.Value = true
	end
end