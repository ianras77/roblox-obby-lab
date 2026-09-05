--!strict
local function expect(condition, message)
  assert(condition, message or "contract assertion failed")
end

-- selene: allow(incorrect_standard_library_use)
local definitions = require("../src/shared/Config/StageDefinitions")
-- selene: allow(incorrect_standard_library_use)
local Plan = require("../src/shared/Util/RoutePlan")
local names = {
  "RiverbankWelcome",
  "MoleBurrowBounce",
  "RattyRiverStones",
  "ToadHallGate",
  "LibraryTumble",
  "RunawayCaravan",
  "TavernBarrelHop",
  "CourtroomChaos",
  "JailbreakBars",
  "LaundryCartEscape",
  "BargeCrossing",
  "TrainTunnelDash",
  "WildWoodGusts",
  "BadgerLanternPath",
  "MotorcarMadness",
  "RoadsideConeSprint",
  "HomecomingRingRun",
  "ToadHallFireworks",
}
expect(#definitions == 18)
local ids = {}
local duration = 0
for index, definition in ipairs(definitions) do
  expect(definition.canonicalName == names[index], "canonical order")
  expect(not ids[definition.id], "unique IDs")
  ids[definition.id] = true
  expect(definition.zone == math.ceil(index / 6))
  for _, key in ipairs({ "displayName", "primaryMechanic", "teachingGoal", "role", "analyticsLevelName" }) do
    expect(#definition[key] > 0, key)
  end
  expect(definition.movement.periodSeconds >= 4 and definition.movement.periodSeconds <= 8)
  expect(definition.warningSeconds >= 0.75 and definition.fallingDelay >= 1.25)
  local nodes = Plan.stage(definition)
  expect(#Plan.validate(nodes, definition.path.maxGap, 4) == 0, definition.id)
  expect(nodes[1].x == 0 and nodes[#nodes].x == definition.path.length, "entry/exit")
  expect(nodes[#nodes].width >= 10 and nodes[#nodes].depth >= 10, "checkpoint landing")
  expect(definition.collectible.z > definition.path.width / 2, "optional token")
  expect(definition.assist.helpFailures == 5)
  duration += definition.expectedNoviceSeconds
  local broken = Plan.stage(definition)
  broken[2].x += 30
  expect(#Plan.validate(broken, definition.path.maxGap, 4) > 0, "gap mutation detected")
  broken = Plan.stage(definition)
  broken[2].y = 5
  expect(#Plan.validate(broken, definition.path.maxGap, 4) > 0, "step mutation detected")
  broken = Plan.stage(definition)
  broken[3].stable = false
  expect(#Plan.validate(broken, definition.path.maxGap, 4) > 0, "unstable node mutation detected")
end
expect(duration >= 480 and duration <= 720, "authored time hypothesis")
local ramp = Plan.connector({ x = 0, y = 0, z = 0 }, { x = 16, y = 4, z = 0 })
expect(ramp.slope == 0.25 and ramp.length < 17)
print("campaign: 18 definitions; metadata, route budgets and invalid-route mutations passed")
