local Settings = {
	["ADMIN ID"] = {283053707, 1233219679, 2210786078};
	["GAMEPASS_WHITELIST"] = {
		["EXTRA_BOT"] = {1233219679, 641376333};
		["LUCKY"] =  {1233219679, 641376333};
	};
	["LUCK_MULTIPLIER"] = 1.5;
	-- Bot
	["MIN_BOT_CAP"] = 1;
	["MAX_BOT_SLOT"] = 4;
	["MIN_BOT_ID"] = 1;
	["EXTRA_BOT_ID"] = 4;
	["DATASTORES"] = {
		["BOT_STORE"] = "IdkBot";
		["PLAYER_STORE"] = "IdkPlayer";
	};
	["BOT SLOTS"] = {
		-- Price for slots
		[2] = 1000;
		[3] = 100000;
	}
}

Settings.Tiers = require(script.Tiers)

return Settings