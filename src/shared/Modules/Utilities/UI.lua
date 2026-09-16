local module = {}

--// Services
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

--// Modules
local Modules = RS.Modules
local spr = require(Modules.Utilities.spr)

local fov = game:GetService("Workspace"):WaitForChild("Camera")

local DEBOUNCE = 0.35
local lastActivation = setmetatable({}, {__mode = "k"})
function module.DisplayFrame(targetFrame, config, overrideVisible)
	local blur = Lighting:WaitForChild("LCBlurEffect")
	
	for _, frame in targetFrame.Parent:GetChildren() do -- close other frames
		if not frame:IsA("Frame") then continue end
		if frame ~= targetFrame then
			frame.Size = UDim2.fromScale(0, 0)
			frame.Visible = false
		end
	end

	if config:GetAttribute("IsInstant") then
		targetFrame.Size = config:GetAttribute("Size")
		if not targetFrame.Visible or (overrideVisible and overrideVisible == true) then
			targetFrame.Visible = true
			spr.target(blur, 0.6, 4, {Size = config:GetAttribute("Blur")})
			spr.target(fov, 0.6, 4, {FieldOfView = config:GetAttribute("FOV")})
		elseif not config:GetAttribute("IsTouch") or (overrideVisible and overrideVisible == false) then
			targetFrame.Visible = false
			spr.target(blur, 0.6, 4, {Size = 0})
			spr.target(fov, 0.6, 4, {FieldOfView = 70})
		end
		return
	end

	local currentTime = tick()
	if currentTime - (lastActivation[targetFrame] or 0) < DEBOUNCE then return end
	lastActivation[targetFrame] = currentTime

	if not targetFrame.Visible or (overrideVisible and overrideVisible == true) then
		targetFrame.Visible = true
		spr.target(blur, 0.6, 4, {Size = config:GetAttribute("Blur")})
		spr.target(fov, 0.6, 4, {FieldOfView = config:GetAttribute("FOV")})
		spr.target(targetFrame, 1, 4, {Size = config:GetAttribute("Size")})
	elseif not config:GetAttribute("IsTouch") or (overrideVisible and overrideVisible == false) then
		spr.target(blur, 0.6, 4, {Size = 0})
		spr.target(fov, 0.6, 4, {FieldOfView = 70})
		spr.target(targetFrame, 1, 4, {Size = UDim2.fromScale(0, 0)})
		task.wait(DEBOUNCE)
		targetFrame.Visible = false
	end
end

function module.DisplaySection(targetSection)
	for _, v in pairs(targetSection.Parent:GetChildren()) do
		if not v:IsA("ScrollingFrame") then continue end
		if v ~= targetSection then
			spr.target(v, 1, 4, {Position = UDim2.fromScale(1.5, 0.55)})
		end
	end
	task.wait(.25)
	spr.target(targetSection, 1, 4, {Position = UDim2.fromScale(0.5, 0.55)})
end

-- ChatGPT'd lel
function module.PointVPFToObject(object, viewportFrame, hasAnimation)
    if not object:FindFirstChild("Main") then
        warn("Missing Main part:", object.Name)
        return
    end

    -- Create clone & assign its parent
    local clone = object:Clone()
    if hasAnimation then
        if not viewportFrame:FindFirstChild("WorldModel") then
            Instance.new("WorldModel").Parent = viewportFrame
        end
        clone.Parent = viewportFrame.WorldModel
    else
        clone.Parent = viewportFrame
    end

    local mainPart = clone:FindFirstChild("Main")

	local camera = Instance.new("Camera")
	viewportFrame.CurrentCamera = camera

	-- Use bounding box just for size reference
	local cf, size = clone:GetBoundingBox()

	-- Compute distance based on size (simple method)
	local maxDim = math.max(size.X, size.Y, size.Z)
	local fov = math.rad(camera.FieldOfView)
	local distance = (maxDim / 2) / math.tan(fov / 2)

	-- Add padding so NPCs / wide models don't clip
	distance = distance * 1.6

	-- Camera direction is based on "Main"
	local forward = -mainPart.CFrame.LookVector

	-- Move camera backwards along Main's forward direction
	local cameraPos = cf.Position - forward * distance

	-- Vertical offset (optional)
	local verticalOffset = size.Y * 0.05
	cameraPos += Vector3.new(0, verticalOffset, 0)

	-- Look at the object's center
	camera.CFrame = CFrame.new(cameraPos, cf.Position)

	camera.Parent = viewportFrame

    local function clear()
        camera:Destroy()
        clone:Destroy()
    end
	return clone, clear
end

return module