-- created 11/??/2025
-- updated 4/4/2026

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

--// Modules
local botModule = require(SS.BotModule)

--// Remotes
local Remotes = RS.Remotes
local FinishedRecording = Remotes.FinishedRecording

local FPS = 20

FinishedRecording.OnServerEvent:Connect(function(player, recording, totalFrames, elapsed)
	if typeof(recording) ~= "table" and typeof(totalFrames) ~= "number" and typeof(elapsed) ~= "number" then return end
	if typeof(recording.Initial) ~= "CFrame" then return end
	totalFrames = math.round(totalFrames)
	if math.abs(totalFrames/FPS - elapsed) > 2/FPS then return end
	for i = 1, totalFrames, 1 do
		if typeof(recording.Sequence[i]) ~= "CFrame" then
			return
		end
	end
	for i = 1, totalFrames, 1 do
		if recording.Climbing[i] == nil then
			return
		else
			local r = recording.Climbing[i]
			--if not (r == false or r == -1 or r == 0 or r == 1) then
			--	return
			--end
			if r == true and r ~= -1 and r ~= 0 and r ~= 1 then
				return
			end
		end
	end
	for i = 1, totalFrames, 1 do
		if typeof(recording.Walking[i]) ~= "boolean" then
			return
		end
	end
	for index, data in pairs(recording.Actions) do
		if typeof(index) ~= "string" or typeof(data) ~= "table" then return end
		if index:len() > 1 and index:sub(1, 1) == "S" and tonumber(index:sub(2, index:len())) then
			local num = tonumber(index:sub(2, index:len()))
			if num > totalFrames then return end
			for i, action in pairs(data) do
				if typeof(i) ~= "number" or typeof(action) ~= "string" then return end
				if action == "J" or action == "F" or action == "L" then
				else
					return
				end
			end
		else
			return
		end
	end
	recording.Frames = totalFrames
	botModule.incrementStats(player, player.NonSaveValues.CurrentObby.Value, elapsed)
	local NumOfSlotsUsed = player.NonSaveValues.NumOfSlotsUsed.Value
	local botID = botModule.findBotIDtoOverride(player, elapsed)
	local nonSaveValues = player.NonSaveValues

	if botID == nil then return end -- no botID to replace
	
	botModule.removeBotData(player, botID)
	local obby = nonSaveValues.CurrentObby.Value
	botModule.createBot(player, botID, elapsed, recording, obby, 0)
	Remotes.SendNotification:FireClient(player, "NEW RECORD for Slot "..botID.." in "..obby.."!", "Tada2")
	print("Bot created for "..player.Name..": "..botID)
	
	--if NumOfSlotsUsed >= nonSaveValues.BotCapacity.Value then
	--	-- Bot limit has been reached -> check if we should replace any old bot
	--	print(player.Name..": max bots reached.")
	--	if botID ~= nil then
	--		botModule.removeBotData(player, botID)
	--		local obby = nonSaveValues.CurrentObby.Value
	--		botModule.createBot(player, botID, elapsed, recording, obby, 0)
	--	end
	--else
	--	-- Bot limit has not been reached -> create new bot
	--	local obby = nonSaveValues.CurrentObby.Value
	--	botModule.createBot(player, botID, elapsed, recording, obby, 0)
	--end
end)
