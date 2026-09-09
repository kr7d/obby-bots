if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Framework = ReplicatedStorage.Framework
local Remotes = Framework.Remotes
local RequestCOFolder = Remotes.Towers.Objects.RequestCOFolder
local Kit = ReplicatedStorage.Framework.Kit

local KitSettings = require(ReplicatedStorage.KitSettings)

--> Disable some stuff
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

--> Wait for character
if not player.Character then
	player.CharacterAdded:Wait()
end

--> Initializing
local CharacterManager = require(Kit.Managers.CharacterManager):Init()
local FlipManager = require(Kit.Managers.FlipManager):Init()
local LightingManager = require(Kit.Managers.LightingManager):Init()
local ClientObjectManager = require(Kit.Managers.ClientObjectManager):Init()
local GuiManager = require(Kit.Managers.GuiManager):Init()

--> Load Client Objects
local ClientParts = Workspace:FindFirstChild("ClientParts")
	or (function()
		local newFolder = Instance.new("Folder")
		newFolder.Name = "ClientParts"
		newFolder.Parent = Workspace
		return newFolder
	end)()

--> Request server for objects
local customRepository = ReplicatedStorage:FindFirstChild("ExternalRepositories")
local towerName = "TowerKit"

local currentlyLoading = false
local objectScope

local keptObjects = nil

local function requestObjects(obbyName)
	if currentlyLoading then
		return
	end
	currentlyLoading = true
	if keptObjects then
		keptObjects:Destroy()
		keptObjects = nil
		
		RequestCOFolder:InvokeServer("cleanup")
	end
	
	local receivedObjects, warnings = RequestCOFolder:InvokeServer("request", obbyName)
	if receivedObjects == nil then currentlyLoading = false return end
	local objects = receivedObjects:Clone()
	keptObjects = receivedObjects
	-- Tell server to clean up objects since they have already been replicated
	
		
	objectScope = ClientObjectManager:LoadClientObjects(
		objects,
		ClientParts,
		towerName,
		customRepository:FindFirstChild(towerName)
	)
	currentlyLoading = false
	receivedObjects = nil
	objects = nil

	if warnings then
		for _, warningTable in warnings do
			objectScope:log(warningTable)
		end
	end
end

--> Reset objects on respawn
if KitSettings.ResetOnDeath then
	Players.LocalPlayer.CharacterAdded:Connect(function()
		if objectScope then
			objectScope:cleanup(false, true)
			objectScope = nil :: any
		end

		LightingManager:ResetLighting()
		ClientParts:ClearAllChildren()
		--task.defer(requestObjects)
	end)
end

--local function removeCO(currentObby: string)
--	for _, folder in pairs(workspace.Obbies:GetChildren()) do
--		if folder:FindFirstChild(currentObby.."_ClientFolder") then
--			folder[currentObby.."_ClientFolder"]:Destroy()
--		end
--	end
--end

local currentlyLoadedObby = nil

player:WaitForChild("NonSaveValues"):WaitForChild("CurrentObby"):GetPropertyChangedSignal("Value"):Connect(function()
	local currentObby = player.NonSaveValues.CurrentObby.Value
	
	if currentObby == "NONE" then
		currentlyLoadedObby = nil
		ClientParts:ClearAllChildren()
		return
	end

	currentlyLoadedObby = currentObby

	if objectScope then
		objectScope:cleanup(false, true)
		objectScope = nil :: any
	end

	LightingManager:ResetLighting()
	ClientParts:ClearAllChildren()
	task.defer(requestObjects, currentlyLoadedObby)

	--player.CharacterAdded:Connect(function()
	--	for _, folder in pairs(workspace.Obbies:GetChildren()) do
	--		if folder:FindFirstChild(currentObby.."_ClientFolder") then
	--			folder[currentObby.."_ClientFolder"]:Destroy()
	--		end
	--	end
	--end)
end)

shared.ResetAtStart = function()
	local currentObby = player.NonSaveValues.CurrentObby.Value
	if currentObby ~= "NONE" and currentObby == currentlyLoadedObby then
		if objectScope then
			objectScope:cleanup(false, true)
			objectScope = nil :: any
		end
		ClientParts:ClearAllChildren()
		if keptObjects then
			local objects = keptObjects:Clone()

			objectScope = ClientObjectManager:LoadClientObjects(
				objects,
				ClientParts,
				towerName,
				customRepository:FindFirstChild(towerName)
			)
		end
	end
end

--game.ReplicatedStorage.Remotes.RemoveCO.OnClientEvent:Connect(removeCO)