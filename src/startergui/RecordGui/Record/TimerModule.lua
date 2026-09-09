-- created 11/??/2025
-- updated 11/12/2025

local timerModule = {}

--// TIMER SYSTEM //--

--// Services
local RunService = game:GetService("RunService")

--// UI
local UI = script.Parent.Parent
local timer = UI.Canvas.Topbar.Timer

--// Variables
local running = false
local startTime = 0
local elapsed = 0

--[[
    This function converts the elapsed time into a formatted mm:ss.00
    @param elapsed - The elapsed time.
    @return The formatted elapsed time.
]]
local function formatTime(elapsed)
	local minutes = math.floor(elapsed / 60)
	local seconds = math.floor(elapsed % 60)
	local milliseconds = math.floor((elapsed % 1) * 100)
	return string.format("%02d:%02d.%02d", minutes, seconds, milliseconds)
end

function timerModule.startTimer()
	if running then return end
	running = true
	startTime = tick()
	RunService.RenderStepped:Connect(function()
		if not running then return end
		elapsed = tick() - startTime
		timer.Text = formatTime(elapsed)
	end)
end

function timerModule.stopTimer()
	running = false
	return elapsed
end

function timerModule.resetTimer()
	running = false
	timer.Text = "00:00.00"
end

return timerModule
