local PlaybackModule = {}

PlaybackModule.Active = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bots = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Bots")
local RunService = game:GetService("RunService")

local FPS = 20

local mostRecent = function(a, upper)
	local l2 = 0
	for frame, _ in pairs(a) do
		local index = tonumber(frame:sub(2, frame:len()))
		if index > l2 and index < upper then
			l2 = index
		end
	end
	return l2
end

RunService.RenderStepped:Connect(function()
	for i, playback in pairs(PlaybackModule.Active) do
		local Rig = playback.Rig
		local timePassed = tick()-playback.Start
		if timePassed >= playback.Time then
			Rig:Destroy()
			table.remove(PlaybackModule.Active, i)
			playback = nil
			continue
		end
		local c1 = math.floor(timePassed*FPS)
		local c2 = math.ceil(timePassed*FPS)
		if c2 > playback.Frames then
			Rig:PivotTo(playback.Sequence[playback.Frames])
		else
			if c1 == c2 then
				Rig:PivotTo(playback.Sequence[c1])
			else
				Rig:PivotTo(playback.Sequence[c1]:Lerp(playback.Sequence[c2], (timePassed*FPS)-c1))	
			end
		end
		local climbState = playback.Climbing[math.clamp(c1, 1, playback.Frames)]
		if climbState then
			if playback.Animations.Climbing.IsPlaying then
				playback.Animations.Falling:Stop()
			end
			if playback.Animations.Walking.IsPlaying then
				playback.Animations.Walking:Stop()
			end
			if not playback.Animations.Climbing.IsPlaying then
				playback.Animations.Climbing:Play(0)
			end
			if climbState > 0 and playback.Animations.Climbing.Speed ~= 1 then
				playback.Animations.Climbing:AdjustSpeed(1)
			elseif climbState < 0 and playback.Animations.Climbing.Speed ~= -1 then
				playback.Animations.Climbing:AdjustSpeed(-1)
			elseif climbState == 0 and playback.Animations.Climbing.Speed ~= 0 then
				playback.Animations.Climbing:AdjustSpeed(0)
			end
		else
			if playback.Animations.Climbing.IsPlaying then
				playback.Animations.Climbing:Stop(0)
			end
			local isWalking = playback.Walking[math.clamp(c1, 1, playback.Frames)]
			if isWalking and not playback.Animations.Walking.IsPlaying then
				playback.Animations.Walking:Play()
			elseif not isWalking and playback.Animations.Walking.IsPlaying then
				playback.Animations.Walking:Stop()
			end
		end

		local in1 = mostRecent(playback.Actions, c1)
		if in1 > playback.RecentAction then
			playback.RecentAction = in1
			local index = "S"..tostring(in1)
			if playback.Actions[index] then
				for _, action in pairs(playback.Actions[index]) do
					if action == "J" then
						local jump = playback.Animations.Animator:LoadAnimation(ReplicatedStorage.Animations.Jump)
						jump.Priority = Enum.AnimationPriority.Movement
						jump:Play()
					elseif action == "F" then
						if playback.Animations.Falling.IsPlaying then continue end
						playback.Animations.Falling:Play()
					elseif action == "L" then
						if not playback.Animations.Falling.IsPlaying then continue end
						playback.Animations.Falling:Stop()
					end
				end
			end
		end
	end
end)

PlaybackModule.Play = function(Owner, Id, Recording, Time, BotName)
	local Start = tick()
	local sequence = Recording.Sequence
	local walking = Recording.Walking
	local actions = Recording.Actions
	local climbing = Recording.Climbing
	local Frames = Recording.Frames
	local Rig
	if typeof(BotName) == "string" and Bots:FindFirstChild(BotName) then
		if BotName == "YOU" then
			if script.PlayerRigs:FindFirstChild(Owner.Name) then
				Rig = script.PlayerRigs:FindFirstChild(Owner.Name):Clone()
			else
				Rig = script:WaitForChild("PlaybackRig"):Clone()
			end
		else
			Rig = Bots:FindFirstChild(BotName):Clone()
		end
	else
		Rig = script:WaitForChild("PlaybackRig"):Clone()
	end
	--if script:FindFirstChild("PlayerRigs") and script.PlayerRigs:FindFirstChild(Owner.Name) then
		--Rig = script.PlayerRigs[Owner.Name]:Clone()
	--else
		--Rig = script:WaitForChild("PlaybackRig"):Clone()
	--end
	for _, x in pairs(Rig:GetDescendants()) do
		if x:IsA("BasePart") then
			x.Transparency += 0.5
			x.CollisionGroup = "NeverCollide"
		elseif x:IsA("Decal") then
			x.Transparency += 0.5
		end
	end
	Rig.Parent = workspace.Bots[Owner.Name]
	Rig.Name = Id
	Rig:PivotTo(Recording.Initial)
	local Animator = Rig.Humanoid.Animator
	local Animations = {
		Animator = Animator;
		Walking = Animator:LoadAnimation(ReplicatedStorage.Animations.Walk);
		Climbing = Animator:LoadAnimation(ReplicatedStorage.Animations.Climb);
		Falling = Animator:LoadAnimation(ReplicatedStorage.Animations.Fall)	
	}
	Animations.Walking.Priority = Enum.AnimationPriority.Movement
	Animations.Climbing.Priority = Enum.AnimationPriority.Movement
	Animations.Falling.Priority = Enum.AnimationPriority.Movement
	if climbing[1] then
		Animations.Climbing:Play(0)
		if climbing[1] == 0 then
			Animations.Climbing:AdjustSpeed(0)
		end
	else
		if walking[1] then
			Animations.Walking:Play()
		end
	end
	Recording.Sequence[0] = Recording.Initial
	table.insert(PlaybackModule.Active, {
		Rig = Rig;
		RecentAction = 0;
		Frames = Frames;
		Start = Start;
		Sequence = sequence;
		Walking = walking;
		Actions = actions;
		Climbing = climbing;
		Animations = Animations;
		Owner = Owner;
		Id = Id;
		Time = Time;
	})
end

PlaybackModule.Stop = function(Owner, Id)
	for i, playback in pairs(PlaybackModule.Active) do
		if playback.Owner == Owner and playback.Id == Id then
			playback.Rig:Destroy()
			table.remove(PlaybackModule.Active, i)
			playback = nil
			continue
		end
	end
end

return PlaybackModule