--!strict
local function expect(condition, message)
  assert(condition, message or "contract assertion failed")
end

-- selene: allow(incorrect_standard_library_use)
local Math = require("../src/shared/Util/MovementMath")
-- selene: allow(incorrect_standard_library_use)
local Assist = require("../src/shared/Util/AssistRules")
-- selene: allow(incorrect_standard_library_use)
local Properties = require("../src/shared/Util/PartProperties")
local function near(a, b)
  expect(math.abs(a - b) < 0.000001, tostring(a) .. " != " .. tostring(b))
end
for _, y in ipairs({ -60, 0, 35 }) do
  local x, vertical, z = Math.influence(0, y, 3, 1, 0, 8, 0.1)
  near(vertical, y)
  near(z, 3)
  expect(x > 0 and x <= 1.200001)
end
local x, y, z = Math.influence(0, 22, 2, -1, 0, 8, 0.1)
expect(x < 0)
near(y, 22)
near(z, 2)
x, y, z = Math.influence(16, 10, 5, 1, 0, 8, 0.1)
near(x, 16)
near(y, 10)
near(z, 5)
for _, hz in ipairs({ 30, 60, 120 }) do
  local velocity = 0
  for _ = 1, hz do
    velocity = Math.influence(velocity, 0, 0, 1, 0, 8, 1 / hz)
  end
  near(velocity, 8)
end
near(Math.omega(5), 2 * math.pi / 5)
expect(not pcall(Math.omega, 0))
expect(Math.phase(0, 6, 0.9) == "inactive")
expect(Math.phase(2.5, 6, 0.9) == "warning")
expect(Math.phase(4, 6, 0.9) == "active")
expect(Math.phase(5.5, 6, 0.9) == "recovery")
expect(not Assist.state(1, 10).hint)
expect(Assist.state(2, 10).hint and not Assist.state(2, 10).grace)
expect(Assist.state(3, 10).grace and not Assist.state(3, 10).help)
expect(Assist.state(5, 10).help and Assist.state(0, 90).help)
for _, key in ipairs({
  "Anchored",
  "Size",
  "CFrame",
  "Color",
  "Material",
  "Name",
  "Transparency",
  "CanCollide",
  "CanTouch",
  "CanQuery",
  "Shape",
  "CastShadow",
  "Massless",
  "CollisionGroup",
}) do
  expect(Properties[key], key)
end
expect(not Properties.MisspelledProperty)
print("movement/assist: Y, forward, steering, frame rates, period, phases, help thresholds, property contract passed")

local target = {}
Properties.apply(target, {
  Transparency = 0.6,
  CanCollide = false,
  CanTouch = false,
  CanQuery = false,
  CastShadow = false,
  Massless = true,
  Shape = "Ball",
  CollisionGroup = "Players",
}, true)
expect(
  target.Transparency == 0.6 and target.CanCollide == false and target.CanTouch == false and target.CanQuery == false,
  "properties really applied"
)
expect(
  target.Massless and target.Shape == "Ball" and target.CollisionGroup == "Players" and not target.CastShadow,
  "shape, mass and group applied"
)
expect(not pcall(Properties.apply, {}, { UnknownProperty = true }, true), "unsupported property errors")
print("Build property application tests passed")

expect(not Math.hazardActive("inactive", true), "inactive cannot harm even with stale CanTouch")
expect(not Math.hazardActive("warning", true), "warning cannot harm")
expect(not Math.hazardActive("active", false), "touch-disabled active cannot harm")
expect(Math.hazardActive("active", true), "active damage enabled")
print("hazard activation tests passed")
