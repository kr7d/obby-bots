local Tutorial = {}

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Assets = RS:WaitForChild("Assets")
local Remotes = RS:WaitForChild("Remotes")
local DialogueManager = require(Modules.DialogueManager)
local IconManager = require(Modules.IconManager)
local GS = RS:WaitForChild("Game Settings")
local FeatureFlags = require(GS.FeatureFlags)

local cancelDialogue = function() end -- Function to cancel current dialogue thread

Tutorial.debounceStep1 = false
Tutorial.debounceStep2 = false
Tutorial.debounceStep3 = false

local threads = {}
local function cancelAllThreads()
    for _, thread in threads do
        if not thread or coroutine.status(thread) == "dead" then continue end
        task.cancel(thread)
    end
    threads = {}
end

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

local starter = RS:WaitForChild("Assets").Bots.Starter
local UI = player.PlayerGui:WaitForChild("UI")

-- Executes when player touches Obby Lobby's StartZone
function Tutorial.step1()
    threads[1] = task.spawn(function()
        cancelDialogue()
        Tutorial.debounceStep1 = true
        game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
        game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 0
        local dialogueData = {
            {speaker = starter, text = "Welcome to your first obby!"},
            {speaker = starter, text = "Begin recording yourself by stepping out of the green <font color='rgb(0,255,0)'>Start Zone</font>."},
        }
        local dialogue, cancel = DialogueManager.Create(dialogueData)
        cancelDialogue = cancel
        task.wait(2)
        dialogue:Fire()
    end)
end

-- Executes when player leaves Obby Lobby's StartZone
function Tutorial.step2()
    cancelAllThreads()
    threads[2] = task.spawn(function()
        cancelDialogue()
        Tutorial.debounceStep2 = true
        local dialogueData = {
            {speaker = starter, text = "Get to the red <font color='rgb(255,0,0)'>End Zone</font> as fast as possible!"}
        }
        local dialogue, cancel = DialogueManager.Create(dialogueData)
        cancelDialogue = cancel
    end)
end

-- Executes when player touches Obby Lobby's EndZone when recording
function Tutorial.step3()
    cancelAllThreads()
    cancelDialogue()
    Tutorial.debounceStep3 = true
    game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
    game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 1
    UI.Canvas.Buttons.Visible = true
end

function Tutorial.reset()
    cancelAllThreads()
    cancelDialogue()
    Tutorial.debounceStep1 = false
    Tutorial.debounceStep2 = false
    Tutorial.debounceStep3 = false
    game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 0
    game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 1
end

local function setLockForUI(lock: boolean)
    if lock == true then
        IconManager.getSettingsIcon():lock()
        IconManager.getRebirthIcon():lock()
    else
        IconManager.getSettingsIcon():unlock()
        IconManager.getRebirthIcon():unlock()
    end
	UI.Canvas.Buttons.InventoryButton.Interactable = not lock
	UI.Canvas.Buttons.ShopButton.Interactable = not lock
	UI.Canvas.Buttons.SpectateButton.Interactable = not lock
	UI.Canvas.Frames.Inventory.Slots.ScrollingEnabled = not lock
    UI.Canvas.Frames.Inventory.Slots["1"].Fields.ResetButton.Interactable = not lock
	for _, v in UI.Canvas.Frames.Inventory.Buttons:GetChildren() do
		if not v:IsA("GuiButton") then continue end
		v.Interactable = not lock
	end
end

local function createPulse(element)
	if element:FindFirstChild("Pulse") then return end
    Assets.Pulse:Clone().Parent = element
end

local function destroyPulse(element)
	if not element:FindFirstChild("Pulse") then return end
    element.Pulse:Destroy()
end

local isInventoryPrompted = false

local function promptInventory()
    isInventoryPrompted = true
    if not UI.Canvas.Buttons.InventoryButton:FindFirstChild("Spotlight") then
		Assets.Spotlight:Clone().Parent = UI.Canvas.Buttons.InventoryButton
	end
    setLockForUI(true)
    UI.Canvas.Buttons.InventoryButton.Interactable = true
end

-- Executes on join or when player's win value changes
function Tutorial.inventoryStep()
    -- TODO: Remove flag
    if not FeatureFlags.isEnabled("InventoryStep") then return end
    if player:FindFirstChild("TutorialCompleted") then return end
    if player.Data.PlayerData.Wins.Value < 1 then return end
    if player.Data.Bots.Starter:GetAttribute("SlotEquipped") == 1 then return end
    player.Character.Humanoid.WalkSpeed = 0
	player.Character.Humanoid.JumpPower = 0
    promptInventory()
end

local isSpectatePrompted = false

local function promptSpectate()
    isSpectatePrompted = true
end

-- Executes on join or after starterConnection triggers
function Tutorial.spectateStep()
    -- TODO: Remove flag
    if not FeatureFlags.isEnabled("SpectateStep") then return end
    if player:FindFirstChild("TutorialCompleted") then return end
    if player.Data.Bots.Starter:GetAttribute("SlotEquipped") ~= 1 then print("Starter not equipped to Slot 1") return end
    promptSpectate()
    createPulse(UI.Canvas.Buttons.SpectateButton)
end

local inventoryConnection
inventoryConnection = UI.Canvas.Buttons.InventoryButton.Activated:Connect(function()
    if not isInventoryPrompted then return end
    inventoryConnection:Disconnect()
    UI.Canvas.Buttons.InventoryButton.Interactable = false
    UI.Canvas.Buttons.InventoryButton.Spotlight:Destroy()
    createPulse(UI.Canvas.Frames.Inventory.Slots["1"].Fields.Title.ChangeButton)
    createPulse(UI.Canvas.Frames.Inventory.Bots.Starter)
end)

local starterConnection
task.spawn(function() -- Spawn a new thread to prevent WaitForChild yielding the main thread
    starterConnection = UI.Canvas.Frames.Inventory.Bots:WaitForChild("Starter").Select.Activated:Connect(function()
        if not isInventoryPrompted then return end
        starterConnection:Disconnect()
        setLockForUI(false)
        player.Character.Humanoid.WalkSpeed = 16
        player.Character.Humanoid.JumpPower = 50
        destroyPulse(UI.Canvas.Frames.Inventory.Slots["1"].Fields.Title.ChangeButton)
        destroyPulse(UI.Canvas.Frames.Inventory.Bots.Starter)
        threads[3] = task.spawn(function()
            local dialogueData = {
                {speaker = starter, text = "Great, now I'm completing this obby and earning credits for you!"}
            }
            local dialogue, cancel = DialogueManager.Create(dialogueData)
            cancelDialogue = cancel
            task.wait(5)
            dialogue:Fire()
        end)
        task.wait(0.5) -- Give time for starter's "SlotEquipped" attribute to be set
        Tutorial.spectateStep()
    end)
end)

local spectateConnection
spectateConnection = UI.Canvas.Buttons.SpectateButton.Activated:Connect(function()
    if not isSpectatePrompted then return end
    spectateConnection:Disconnect()
    Remotes.TutorialCompleted:FireServer()
    destroyPulse(UI.Canvas.Buttons.SpectateButton)
end)

return Tutorial