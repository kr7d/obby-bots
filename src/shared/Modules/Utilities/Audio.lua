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

local function ChooseSong(songs, currentSong)
    local length = #songs

    if length == 1 then return songs[1] end

    local random = Random.new()
    local newSong
    repeat
        newSong = songs[random:NextInteger(1, length)]
    until newSong ~= currentSong
    currentSong = newSong
    return currentSong
end

module.PlayFromPlaylist = function(PlaylistName: String): ()
    LoadPlaylist(PlaylistName)
    if not CurrentPlaylist then
        warn("Playlist not found:", PlaylistName)
        return
    end

    local songs = CurrentPlaylist:GetChildren()
    local length = #songs
    local currentSong = songs[1]

    task.spawn(function()
        while CurrentPlaylist do
            currentSong = ChooseSong(songs, currentSong)
            currentSong.Loaded:Wait()
            currentSong:Play()
            wait(currentSong.TimeLength)
        end
    end)
end

return module
