--!strict
local FeatureFlags = {}

type FlagName = "InventoryStep"

local FLAGS = {
    InventoryStep = false,
}

function FeatureFlags.isEnabled(flagName: FlagName): boolean
    return FLAGS[flagName]
end

return FeatureFlags