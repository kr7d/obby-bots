--// EDIT STUFF HERE:
local ADMINRANK = 254 -- What rank in group for admin


--// MAIN SCRIPT
local AdminFunctions = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// General
function AdminFunctions.IsPlayerAdmin(Player, AdminList) -- checks if user is allowed to use commands
	if table.find(AdminList, Player.UserId) then return true end -- In table
	
	local IsGroupGame = game.CreatorType == Enum.CreatorType.Group
	local CreatorId = game.CreatorId

	if IsGroupGame then
		return Player:GetRankInGroup(CreatorId) >= ADMINRANK
	else
		return CreatorId == Player.UserId
	end
end

function AdminFunctions.FindPlayerFromName(PlayerName, Player)
	if string.lower(PlayerName) == "me" then return Player end
	for _, player in Players:GetPlayers() do
		if string.lower(player.Name) == PlayerName then
			return player
		end
	end
end

--// Stats
function AdminFunctions.FindStatFromStatName(Player, StatName)
	for _, Stat in Player.Data:GetDescendants() do
		if string.lower(Stat.Name) == StatName then
			return Stat
		end
	end
end

return AdminFunctions