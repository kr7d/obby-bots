local module = {}

module.PlayAudio = function(Soundname, Volume)
	coroutine.wrap(function()
		local Sound = game.ReplicatedStorage.Assets.Sounds[Soundname]:Clone()
		Sound.Volume = Volume or Sound.Volume
		Sound.Parent = game.SoundService
		Sound:Play()
		wait(Sound.TimeLength)
		Sound:Destroy()
	end)()
end

local CurrentPlaylist = nil

module.StopPlaylist = function(): ()
    if not CurrentPlaylist then return end
    CurrentPlaylist:Destroy()
    CurrentPlaylist = nil
end

local function LoadPlaylist(PlaylistName: String): ()
    module.StopPlaylist()
    CurrentPlaylist = game.ReplicatedStorage.Assets.Music:FindFirstChild(PlaylistName)
    if CurrentPlaylist then
        CurrentPlaylist = CurrentPlaylist:Clone()
        CurrentPlaylist.Parent = game.SoundService
    else
        CurrentPlaylist = nil
    end
end

module.PlayFromPlaylist = function(PlaylistName: String): ()
    LoadPlaylist(PlaylistName)
    if not CurrentPlaylist then
        warn("Playlist not found:", PlaylistName)
        return
    end

	local songs = CurrentPlaylist:GetChildren()
    local length = #songs
    local currentSong
	local currentIteration = Random.new():NextInteger(1, #songs)
    task.spawn(function()
		while CurrentPlaylist.Parent ~= nil do
			if currentSong then
				currentSong:Stop()
			end
			currentSong = songs[currentIteration]
			if currentIteration == #songs then
				currentIteration = 1
			else
				currentIteration += 1
			end
			if not currentSong.IsLoaded then
				currentSong.Loaded:Wait()
			end
            currentSong:Play()
            wait(currentSong.TimeLength)
        end
    end)
end

return module
