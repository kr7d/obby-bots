local Tutorial = {}

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local DialogueManager = require(Modules.DialogueManager)

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
end

-- Executes when player touches Obby Lobby's StartZone
function Tutorial.step1()
    threads[1] = task.spawn(function()
        cancelDialogue()
        Tutorial.debounceStep1 = true
        game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
        game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 0
        local dialogueData = {
            {speaker = "Tutorial", text = "Welcome to your first obby!"},
            {speaker = "Tutorial", text = "Begin recording yourself by stepping out of the green Start Zone."},
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
            {speaker = "Tutorial", text = "Get to the red End Zone as fast as possible!"}
        }
        local dialogue, cancel = DialogueManager.Create(dialogueData)
        cancelDialogue = cancel
    end)
end

-- Executes when player touches Obby Lobby's EndZone when recording
function Tutorial.step3()
    cancelAllThreads()
    threads[3] = task.spawn(function()
        cancelDialogue()
        Tutorial.debounceStep3 = true
        game.Workspace.Obbies["Obby Lobby"].Obby.StartHighlight.Transparency = 1
        game.Workspace.Obbies["Obby Lobby"].Obby.EndHighlight.Transparency = 1
        local dialogueData = {
            {speaker = "Tutorial", text = "Congrats on beating your first obby!"}
        }
        local dialogue, cancel = DialogueManager.Create(dialogueData)
        cancelDialogue = cancel
        task.wait(5)
        dialogue:Fire()
    end)
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

return Tutorial