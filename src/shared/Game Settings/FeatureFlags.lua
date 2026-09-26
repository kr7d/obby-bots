--!strict
local FeatureFlags = {}

type FlagName = "InventoryStep" | "SpectateStep" | "ProfileIcon"

local FLAGS = {
    InventoryStep = true,
    SpectateStep = true,
    ProfileIcon = true
}

function FeatureFlags.isEnabled(flagName: FlagName): boolean
    return FLAGS[flagName]
end

return FeatureFlags