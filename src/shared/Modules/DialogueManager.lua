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

function module.Create(dialogueData: {{speaker: string, text: string}})
    local dialogue = UI.Canvas.Dialogue
    dialogue.Visible = true
    local connection = Instance.new("BindableEvent")
    task.spawn(function()
        for _, line in dialogueData do
            dialogue.Button.Speaker.Text = line.speaker
            Utilities.Typewrite.Create(dialogue.Button.TextLabel, line.text)
            connection.Event:Wait()
        end
        UI.Canvas.Dialogue.Visible = false
        connection:Destroy()
    end)
    return connection
end


return module