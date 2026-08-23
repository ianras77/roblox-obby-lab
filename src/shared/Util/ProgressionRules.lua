--!strict

-- Pure progression rules live here so they can be tested without Roblox services.
local ProgressionRules = {}

function ProgressionRules.normalizeCheckpoint(value: any): number
  if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
    return 0
  end
  return math.max(0, value)
end

function ProgressionRules.canAdvance(previousValue: any, requestedValue: any, totalStages: number): boolean
  local previous = ProgressionRules.normalizeCheckpoint(previousValue)
  if type(requestedValue) ~= "number" or requestedValue ~= requestedValue or requestedValue % 1 ~= 0 then
    return false
  end
  return requestedValue >= 1 and requestedValue <= totalStages and requestedValue == previous + 1
end

return ProgressionRules
