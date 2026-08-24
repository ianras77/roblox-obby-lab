--!strict
-- selene: allow(incorrect_standard_library_use)

local ProgressionRules = require("../src/shared/Util/ProgressionRules")

local function expect(condition: boolean, message: string)
  assert(condition, message)
end

expect(ProgressionRules.normalizeCheckpoint(nil) == 0, "nil checkpoint defaults to zero")
expect(ProgressionRules.normalizeCheckpoint(3.5) == 0, "fractional checkpoint is rejected")
expect(ProgressionRules.normalizeCheckpoint(-2) == 0, "negative checkpoint is clamped")
expect(ProgressionRules.normalizeCheckpoint(4) == 4, "integer checkpoint is retained")
expect(ProgressionRules.normalizeCheckpoint(math.huge) == 0, "infinite checkpoint is rejected")

expect(ProgressionRules.canAdvance(nil, 1, 18), "a new run can enter chapter one")
expect(ProgressionRules.canAdvance(1, 2, 18), "progress advances one chapter")
expect(not ProgressionRules.canAdvance(1, 1, 18), "duplicate checkpoint is ignored")
expect(not ProgressionRules.canAdvance(1, 3, 18), "checkpoint jumps are rejected")
expect(not ProgressionRules.canAdvance(18, 19, 18), "route overflow is rejected")
expect(not ProgressionRules.canAdvance(1, 2.5, 18), "fractional checkpoint input is rejected")
expect(not ProgressionRules.canAdvance(1, 2, math.huge), "infinite route size is rejected")
expect(not ProgressionRules.canAdvance(1, 2, 0), "empty route size is rejected")

print("progression rules tests passed")
