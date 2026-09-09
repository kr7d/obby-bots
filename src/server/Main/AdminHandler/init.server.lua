--[[ This Script Handles Admin Commands

Current Commands:
/setcredits PlayerName Amount
/setbot PlayerName BotName Tier Copies

]]

--------- Main Script ---------

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// Modules
local Modules = ReplicatedStorage.Modules
local Settings = require(ReplicatedStorage["Game Settings"].Settings)
local BotModule = require(SS.BotModule)

--// Variables
local ADMINS = Settings["ADMIN ID"]

local AdminFunctions = require(script.AdminFunctions)

function Main(Player) -- this code is called for each player joining
	if not AdminFunctions.IsPlayerAdmin(Player, ADMINS) then return end -- player is not an admin if this returns false

	Player.Chatted:Connect(function(Message)
		local SplittedMessage = string.split(Message, " ")
		local Command = string.lower(SplittedMessage[1])
		local PlayerName = SplittedMessage[2] and string.lower(SplittedMessage[2]) or ""
		local Arg1 = SplittedMessage[3] and string.lower(SplittedMessage[3]) or ""
		local Arg2 = SplittedMessage[4] and string.lower(SplittedMessage[4]) or ""
		local Arg3 = SplittedMessage[5] and string.lower(SplittedMessage[5]) or ""
		
		if Command == "/setcredits" then -- /givecredits PlayerName Amount
			local TargetPlayer = AdminFunctions.FindPlayerFromName(PlayerName, Player)
			if TargetPlayer == nil then return end -- no player exists
			
			local Stat = TargetPlayer.Data.PlayerData.Credits
			if Stat == nil then return end -- stat does not exist
			
			if Stat:IsA("IntValue") or Stat:IsA("NumberValue") then
				Arg1 = tonumber(Arg1)
				if Arg1 == nil then return end
				Stat.Value = Arg1
			end
		elseif Command == "/setbot" then -- /setbot PlayerName BotName Tier Copies
			local TargetPlayer = AdminFunctions.FindPlayerFromName(PlayerName, Player)
			if TargetPlayer == nil then return end
			
			local BotName = (string.gsub(Arg1, "_", " "))
			local Bot = BotModule.FindBotFromBotName(BotName)
			if Bot == nil then return end -- bot doesn't exist
			
			Arg2 = tonumber(Arg2)
			Arg3 = tonumber(Arg3)
			
			if Arg2 ~= nil and (Arg2 < 1 or Arg2 > 10) then warn("Tier out of bounds") return end
			if Arg3 ~= nil and Arg3 < 0 then warn("Copies out of bounds") return end
			
			local BotFolder = BotModule.FindBotFolder(TargetPlayer, Bot)
			if BotFolder ~= nil then
				if Arg2 ~= nil then
					BotFolder:SetAttribute("Tier", Arg2)
					BotFolder:SetAttribute("Multiplier", Bot.Settings.BaseMultiplier.Value*(Settings.Tiers.TIER_MULTIPLIER^(BotFolder:GetAttribute("Tier")-1)))
				end
				if Arg3 ~= nil then BotFolder:SetAttribute("Copies", Arg3) end
			else
				local NewBotFolder = BotModule.CreateNewBotFolder(Player, Bot)
				if Arg2 ~= nil then
					NewBotFolder:SetAttribute("Tier", Arg2)
					NewBotFolder:SetAttribute("Multiplier", Bot.Settings.BaseMultiplier.Value*(Settings.Tiers.TIER_MULTIPLIER^(NewBotFolder:GetAttribute("Tier")-1)))
				end
				if Arg3 ~= nil then NewBotFolder:SetAttribute("Copies", Arg3) end
				NewBotFolder.Parent = TargetPlayer.Data.Bots
			end
		elseif Command == "/deletebot" then -- /deletebot PlayerName BotName
			local TargetPlayer = AdminFunctions.FindPlayerFromName(PlayerName, Player)
			if TargetPlayer == nil then return end
			
			if Arg1 == "all" then
				for _, BotFolder in TargetPlayer.Data.Bots:GetChildren() do
					BotFolder:Destroy()
				end
				return
			end
			
			local BotName = (string.gsub(Arg1, "_", " "))
			local Bot = BotModule.FindBotFromBotName(BotName)
			if Bot == nil then return end
			
			local BotFolder = BotModule.FindBotFolder(TargetPlayer, Bot)
			if not BotFolder then return end
			
			BotFolder:Destroy()
		elseif Command == "/noclip" then -- /noclip PlayerName
			local TargetPlayer = AdminFunctions.FindPlayerFromName(PlayerName, Player)
			if TargetPlayer == nil then return end
			
			local noclip = SS.Noclip:Clone()
			noclip.Parent = TargetPlayer.Backpack
		elseif Command == "/speed" then
			local TargetPlayer = AdminFunctions.FindPlayerFromName(PlayerName, Player)
			if TargetPlayer == nil then return end
			
			Arg1 = tonumber(Arg1)
			if Arg1 == nil then return end
			
			TargetPlayer.Character.Humanoid.WalkSpeed = Arg1
		end
	end)
end

Players.PlayerAdded:Connect(Main)