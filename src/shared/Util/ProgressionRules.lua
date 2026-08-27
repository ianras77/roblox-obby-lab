--!strict

-- Pure progression rules live here so they can be tested without Roblox services.
local ProgressionRules = {}

local function isFiniteNumber(value: any): boolean
  return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function ProgressionRules.normalizeCheckpoint(value: any): number
  if not isFiniteNumber(value) or value % 1 ~= 0 then
    return 0
  end
  return math.max(0, value)
end

function ProgressionRules.canAdvance(previousValue: any, requestedValue: any, totalStages: number): boolean
  local previous = ProgressionRules.normalizeCheckpoint(previousValue)
  if not isFiniteNumber(requestedValue) or requestedValue % 1 ~= 0 then
    return false
  end
  if not isFiniteNumber(totalStages) or totalStages % 1 ~= 0 or totalStages < 1 then
    return false
  end
  return requestedValue >= 1 and requestedValue <= totalStages and requestedValue == previous + 1
end

return ProgressionRules
