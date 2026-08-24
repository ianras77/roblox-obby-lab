--!strict

local RunRules = {}

function RunRules.isValidStage(stageIndex: unknown, totalStages: number): boolean
  return type(stageIndex) == "number" and stageIndex % 1 == 0 and stageIndex >= 1 and stageIndex <= totalStages
end

function RunRules.isEligibleCompletion(mode: string, elapsed: number, minimumTimeTrialSeconds: number): boolean
  if
    (mode ~= "Adventure" and mode ~= "TimeTrial")
    or elapsed < 0
    or elapsed ~= elapsed
    or math.abs(elapsed) == math.huge
  then
    return false
  end
  return mode ~= "TimeTrial" or elapsed >= math.max(0, minimumTimeTrialSeconds)
end

return RunRules
