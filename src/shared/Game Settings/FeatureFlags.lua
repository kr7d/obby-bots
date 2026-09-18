--!strict
local FeatureFlags = {}

type FlagName = "InventoryStep" | "SpectateStep"

local FLAGS = {
    InventoryStep = true,
    SpectateStep = true
}

function FeatureFlags.isEnabled(flagName: FlagName): boolean
    return FLAGS[flagName]
end

return FeatureFlags