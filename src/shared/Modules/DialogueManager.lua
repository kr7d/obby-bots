local module = {}

--// Services
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Modules = RS:WaitForChild("Modules")
local Utilities = require(Modules.Utilities)

--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Variables
local UI = player.PlayerGui:WaitForChild("UI")
local Assets = RS:WaitForChild("Assets")

function module.Create(dialogueData: {{speaker: model, text: string}})
    local dialogue = UI.Canvas.Dialogue
    dialogue.Visible = true
    local connection = Instance.new("BindableEvent")
    local freeVPF = function() end
    local thread = task.spawn(function()
        for _, line in dialogueData do
            local _, free = Utilities.UI.PointVPFToObject(line.speaker, dialogue.Button.Display)
            freeVPF = free
            dialogue.Button.Display.TextLabel.Text = line.speaker.Name
            Utilities.Typewrite.Create(dialogue.Button.TextLabel, line.text)
            connection.Event:Wait()
            freeVPF()
        end
        UI.Canvas.Dialogue.Visible = false
        connection:Destroy()
    end)
    local function cancel()
        if coroutine.status(thread) == "dead" then return end
        task.cancel(thread)
        UI.Canvas.Dialogue.Visible = false
        freeVPF()
        connection:Destroy()
    end
    return connection, cancel
end


return module