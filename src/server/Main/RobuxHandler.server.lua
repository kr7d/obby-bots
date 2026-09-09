--// Services
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Variables

local GamepassFolder = ReplicatedStorage.Gamepasses

function GetGamepassFromID(ID)
	for _, Gamepass in GamepassFolder:GetChildren() do
		if Gamepass.Value == ID then
			return Gamepass
		end
	end
	return nil
end

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(Player, Gamepass, Succes)
	if not Succes then return end

	local GamepassType = GetGamepassFromID(Gamepass)
	if GamepassType == nil then return end -- Gamepass does not exist in the game	

	local GP = Player.Data.Gamepasses:FindFirstChild(GamepassType.Name)
	if not GP then warn("Gamepass: "..GamepassType.Name.." does not exist in Player.Data.Gamepasses") return end

	GP.Value = true
end)