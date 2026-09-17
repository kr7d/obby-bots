--!strict
local FeatureFlags = {}

type FlagName = "TutorialClearEnabled"

local FLAGS = {
    TutorialClearEnabled = false,
}

function FeatureFlags.isEnabled(flagName: FlagName): boolean
    return FLAGS[flagName]
end

return FeatureFlags