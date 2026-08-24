--!strict
-- selene: allow(incorrect_standard_library_use)

local RunRules = require("../src/shared/Util/RunRules")

local function expect(condition: boolean, message: string)
  assert(condition, message)
end

expect(RunRules.isValidStage(1, 18), "first stage is valid")
expect(RunRules.isValidStage(18, 18), "last stage is valid")
expect(not RunRules.isValidStage(0, 18), "zero stage is rejected")
expect(not RunRules.isValidStage(2.5, 18), "fractional stage is rejected")
expect(not RunRules.isValidStage(19, 18), "overflow stage is rejected")
expect(not RunRules.isValidStage(math.huge, 18), "infinite stage is rejected")

expect(RunRules.isEligibleCompletion("Adventure", 1, 30), "adventure completion is eligible")
expect(RunRules.isEligibleCompletion("TimeTrial", 30, 30), "minimum time trial is eligible")
expect(not RunRules.isEligibleCompletion("TimeTrial", 29.9, 30), "short time trial is rejected")
expect(not RunRules.isEligibleCompletion("Practice", 100, 30), "practice is never eligible")
expect(not RunRules.isEligibleCompletion("Admin", 100, 0), "unsupported modes are never eligible")
expect(not RunRules.isEligibleCompletion("Adventure", -1, 0), "negative elapsed time is rejected")
expect(not RunRules.isEligibleCompletion("Adventure", math.huge, 0), "infinite elapsed time is rejected")

print("run rules tests passed")
