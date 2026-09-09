--// Player & Loading
local player = game.Players.LocalPlayer
repeat wait() until player:FindFirstChild("Loaded") and player.Loaded.Value or player.Parent == nil

if player.Parent == nil then return end

--// Variables
local frame = player.PlayerGui.UI.Canvas.Frames.SpectateFrame.Frame
local previous = frame.Prev
local next = frame.Next
local status = frame.Status.CurrentPlayer
local camera = game.Workspace.CurrentCamera
local currentBot = nil
local num = 1

status.Text = "N/A"

function sortByName(bots)
	table.sort(bots, function(a, b)
		return a.Name < b.Name
	end)
	return bots
end

frame.Parent:GetPropertyChangedSignal("Visible"):Connect(function()
	local visible = frame.Parent.Visible
	if not visible then
		camera.CameraSubject = player.Character.Humanoid
		status.Text = "N/A"
		return
	end
	local playerBots = workspace.Bots:FindFirstChild(player.Name)
	if playerBots == nil then return end
	local bots = playerBots:GetChildren()
	bots = sortByName(bots)
	currentBot = bots[num]
	if not currentBot then return end
	camera.CameraSubject = currentBot.Humanoid
	status.Text = "Slot #"..currentBot.Name
end)

previous.MouseButton1Click:Connect(function()
	local playerBots = workspace.Bots:FindFirstChild(player.Name)
	if playerBots == nil then return end
	local bots = playerBots:GetChildren()
	bots = sortByName(bots)
	local max = #bots
	num = num - 1
	if num < 1 then num = max end
	currentBot = bots[num]
	if not currentBot then return end
	camera.CameraSubject = currentBot.Humanoid
	status.Text = "Slot #"..currentBot.Name
end)

next.MouseButton1Click:Connect(function()
	local playerBots = workspace.Bots:FindFirstChild(player.Name)
	if playerBots == nil then return end
	local bots = playerBots:GetChildren()
	bots = sortByName(bots)

	local max = #bots
	num = num + 1
	if num > max then num = 1 end
	currentBot = bots[num]
	if not currentBot then return end
	camera.CameraSubject = currentBot.Humanoid
	status.Text = "Slot #"..currentBot.Name
end)

task.spawn(function()
	while true do
		task.wait()
		if currentBot == nil then continue end
		currentBot.Destroying:Connect(function()
			if frame.Parent.Visible then
				local playerBots = workspace.Bots:FindFirstChild(player.Name)
				if playerBots == nil then return end
				currentBot = playerBots:WaitForChild(currentBot.Name)
				camera.CameraSubject = currentBot.Humanoid
			end
		end)
	end
end)