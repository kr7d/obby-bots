-- created 11/??/2025
-- updated 11/24/2025

local FPS = 20

--// Services
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")


--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

local character = player.Character

--// Modules
local timerModule = require(player.PlayerGui.Record.Record.TimerModule)

--// Remotes
local Remotes = RS.Remotes
local FinishedRecording = Remotes.FinishedRecording
local SetCurrentObby = Remotes.SetCurrentObby

--// Zones
local startZones = game.Workspace.Zones.StartZones
local endZones = game.Workspace.Zones.EndZones
local validZones = game.Workspace.Zones.ValidZones

--// Variables
local nonSaveValues = player.NonSaveValues
local replaying = true
local isRecording = nonSaveValues.IsRecording
local recording
local Tracked = character or player.CharacterAdded:Wait()
local HMR = Tracked:WaitForChild("HumanoidRootPart")
local Humanoid = Tracked:WaitForChild("Humanoid")
local start = nil

local climbing = false
local currentSpeed = 0

Humanoid.Climbing:Connect(function(climbingSpeed)
	if climbingSpeed > 0 then
		climbing = 1
	elseif climbingSpeed < 0 then
		climbing = -1
	else
		climbing = 0
	end
end)

Humanoid.Running:Connect(function(speed)
	currentSpeed = speed
end)

local function addAction(index, action)
	if recording.Actions[index] then
		if table.find(recording.Actions[index], action) == nil then
			table.insert(recording.Actions[index], action)
		end
	else
		recording.Actions[index] = {action}
	end
end

Humanoid.StateChanged:Connect(function(state)
	if recording then
		local passed = tick()-start
		local Frame = math.round(passed*FPS)
		if Frame == 0 then return end
		local index = "S"..tostring(Frame)
		if state == Enum.HumanoidStateType.Jumping then
			addAction(index, "J")
		elseif state == Enum.HumanoidStateType.Freefall then
			addAction(index, "F")
		elseif state == Enum.HumanoidStateType.Landed then
			addAction(index, "L")
		end
	end
end)

local function stopRecording()
	if not recording then return end
	isRecording.Value = false
	timerModule.stopTimer()
	recording = nil
end

local function record(enabled)
	if not enabled then
		isRecording.Value = false
		local elapsed = timerModule.stopTimer()
		local totalFrames = 0
		for frame, _ in pairs(recording.Sequence) do
			if frame > totalFrames then
				totalFrames = frame
			end
		end
		for i = 1, totalFrames, 1 do
			if recording.Sequence[i] == nil then
				if recording.Sequence[i-1] and recording.Sequence[i+1] then
					recording.Sequence[i] = recording.Sequence[i-1]:Lerp(recording.Sequence[i+1], 0.5)
				else
					recording.Sequence[i] = recording.Sequence[i-1]
				end
			end
		end
		for i = 1, totalFrames, 1 do
			if recording.Climbing[i] == nil then
				if recording.Climbing[i-1] == nil then
					recording.Climbing[i] = false
				else
					recording.Climbing[i] = recording.Climbing[i-1]
				end
			end
		end
		for i = 1, totalFrames, 1 do
			if recording.Walking[i] == nil then
				if recording.Walking[i-1] == nil then
					recording.Walking[i] = false
				else
					recording.Walking[i] = recording.Walking[i-1]
				end
			end
		end
		recording.Initial = recording.Sequence[0]
		FinishedRecording:FireServer(recording, totalFrames, elapsed)
		return
	end
	shared.ResetAtStart()
	recording = {
		Walking = {};
		Actions = {};
		Sequence = {[0] = HMR.CFrame};
		Climbing = {};
	}
	if currentSpeed > 0 then
		recording.Walking[1] = true
	end
	recording.Climbing[1] = climbing
	start = tick()
	isRecording.Value = true
	timerModule.startTimer()
end

--// Touch Detection
local QuerySettings = OverlapParams.new()
QuerySettings.FilterType = Enum.RaycastFilterType.Include
QuerySettings.MaxParts = 2
QuerySettings.RespectCanCollide = false
QuerySettings.FilterDescendantsInstances = {startZones, endZones, validZones}

local currentZone = nil
local inValidZone = false

RunService.RenderStepped:Connect(function()
	if shared.ResetAtStart == nil then return end
	local currentObby = nonSaveValues:FindFirstChild("CurrentObby").Value
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart == nil then return end
	
	if recording then
		local passed = tick()-start
		local Frame = math.round(passed*FPS)
		if Frame > 0 then
			if currentSpeed > 0 then
				recording.Walking[Frame] = true
			else
				recording.Walking[Frame] = false
			end
			recording.Sequence[Frame] = HMR.CFrame
			if Humanoid:GetState() == Enum.HumanoidStateType.Climbing then
				recording.Climbing[Frame] = climbing
			else
				recording.Climbing[Frame] = false
			end
		end
	end
	
	local partsInHRP = workspace:GetPartsInPart(HumanoidRootPart, QuerySettings)
	local query = {}
	-- Force ValidZone to always be index 2
	for _, v in pairs(partsInHRP) do
		if v.Parent == validZones then
			query[2] = v
			continue
		end
		query[1] = v
	end
	
	if query[2] and not player.Data.Obbies:FindFirstChild(query[2].Name) then return end
	
	local isTutorialInProgress = currentObby == "Obby Lobby" and player.Data.PlayerData.Wins.Value == 0 and not player:FindFirstChild("TutorialCompleted")
	
	if not query[1] and query[2] then
		query = query[2]
		local zone = query.Parent
		-- TouchEnded: StartZone
		if currentZone and currentZone == startZones then
			if isRecording.Value then return end
			record(true)
		end
		-- TouchBegan: ValidZone
		if zone == validZones and not inValidZone then
			inValidZone = true
			SetCurrentObby:FireServer(query.Name)
		end
		currentZone = zone
	elseif query[1] and query[2] then
		query = query[1]
		local zone = query.Parent
		-- TouchBegan: Start Zone
		if zone == startZones and query.Name == currentObby then
			timerModule.resetTimer()
			stopRecording()
			currentZone = zone
			if isTutorialInProgress then
				game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
				game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 0
			end
		-- TouchBegan: End Zone
		elseif zone == endZones and query.Name == currentObby then
			if not isRecording.Value then return end
			record(false)
			currentZone = zone
			if isTutorialInProgress then
				game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
				game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 1
			end
		end
	elseif not query[1] and not query[2] then
		-- TouchEnded: Valid Zone
		if inValidZone then
			print("LEFT VALID ZONE")
			inValidZone = false
			timerModule.resetTimer()
			stopRecording()
			if isTutorialInProgress then
				game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 0
				game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 1
			end
			SetCurrentObby:FireServer("NONE")
		end
		currentZone = nil
	end
end)

player.CharacterAdded:Connect(function(char)
	character = char
	Tracked = character
	HMR = Tracked:WaitForChild("HumanoidRootPart")
	Humanoid = Tracked:WaitForChild("Humanoid")
end)