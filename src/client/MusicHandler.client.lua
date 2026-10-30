local RS = game:GetService("ReplicatedStorage")
local Modules = RS:WaitForChild("Modules")

local Utilities = require(Modules.Utilities)

Utilities.Audio.PlayFromPlaylist("World1")