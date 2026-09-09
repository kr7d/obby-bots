return {
	["Folders"] = {
		"PlayerData",
		"NonSaveValues",
		"Bots",
		"Gamepasses",
		"Obbies",
	},
	
	["SaveValues"] = {
		["PlayerData"] = {
			{Name = "Credits", Value = 0, ID = 1, Type = "NumberValue"},
			{Name = "Wins", Value = 0, ID = 2, Type = "IntValue"},
			{Name = "Rebirth", Value = 0, ID = 3, Type = "NumberValue"},
			{Name = "ShowOtherPlayers", Value = true, ID = 4, Type = "BoolValue"},
			{Name = "Music", Value = true, ID = 5, Type = "BoolValue"},
			{Name = "OwnsBot2", Value = false, ID = 6, Type = "BoolValue"},
			{Name = "OwnsBot3", Value = false, ID = 7, Type = "BoolValue"},
			{Name = "OwnsBot4", Value = false, ID = 8, Type = "BoolValue"},

			--// Statistics
			{Name = "TotalCredits", Value = 0, ID = 9, Type = "IntValue"},
			{Name = "WPS", Value = 0, ID = 10, Type = "NumberValue"}
		},
		["Gamepasses"] = {
			{Name = "ExtraBot", Value = false, ID = 1, Type = "BoolValue"},
			{Name = "Lucky", Value = false, ID = 2, Type = "BoolValue"},
		}
	},
	
	["NonSaveValues"] = {
		{Name = "IsRecording", Value = false, Type = "BoolValue"},
		{Name = "CurrentObby", Value = "NONE", Type = "StringValue"},
		{Name = "BotCapacity", Value = 0, Type = "IntValue"},
		{Name = "NumOfSlotsUsed", Value = 0, Type = "IntValue"},
		{Name = "CurrentChest", Value = nil, Type = "ObjectValue"},
		{Name = "IsOpeningChest", Value = false, Type = "BoolValue"},
	},
}