-- selene: allow(incorrect_standard_library_use)
-- selene: allow(shadowing)
-- Executes production modules against explicit headless service adapters.
-- This is NOT Studio, engine physics, renderer, networking, or live backend proof.
local Environment = require("./Environment")
local process = require("@lune/process")
local env = Environment.new(process.args[1] or "/tmp/toads-production-playability.rbxlx")
local V, CF = env.roblox.Vector3, env.roblox.CFrame
local start = os.clock()
local service = env:require(env.game.ServerScriptService.Services.ObbyService).new()
local function expect(condition, message)
  assert(condition, message)
end
local function root(player)
  return player.Character:FindFirstChild("HumanoidRootPart")
end
local function touchCheckpoint(player, index)
  local stage = service.world.stages[index]
  service.checkpoints:teleportToCFrame(player, stage.safeSpawn)
  service.checkpoints:onCheckpointTouched(index, stage.checkpoint, root(player))
end
expect(#service.world.stages == 18, "world builds all stages")
local validator = env:require(env.game.ServerScriptService.WorldGen.RouteValidator)
local function validate()
  env.invalidateGeometry()
  validator.assertWorld(service.world.stages, service.world.model, service.world.model.SpawnPad)
end
-- Mutation guards execute the production validator with independent analytic rays.
local pad = service.world.stages[1].model:FindFirstChild("MainPath_4", true)
local parent = pad.Parent
pad.Parent = nil
expect(not pcall(validate), "missing actual generated support must fail")
pad.Parent = parent
env.collection:AddTag(pad, "MovingPlatform")
env.collection:AddTag(pad, "Rotator")
expect(not pcall(validate), "transform ownership mutation must fail")
env.collection:RemoveTag(pad, "MovingPlatform")
env.collection:RemoveTag(pad, "Rotator")
validate()
print("HEADLESS geometry: actual 18-stage generation and validator; missing-support/controller mutations passed")

for _, count in ipairs({ 1, 2, 8 }) do
  local players = {}
  for index = 1, count do
    players[index] = env:addPlayer(count * 100 + index, index == count and 0.2 or nil)
  end
  env:advance(0.4)
  for _, player in ipairs(players) do
    expect(service.checkpoints:isLoaded(player), "late join/profile load")
    expect(root(player) ~= nil, "delayed character root")
    local snapshot = service.world.stateFunction.OnServerInvoke(player)
    expect(
      snapshot.ready and snapshot.total == 18 and snapshot.totalKeys == 18 and snapshot.stage == 0,
      "initial snapshot"
    )
    expect(snapshot.settings and snapshot.assist and snapshot.chapter, "snapshot fields")
  end
  local first = players[1]
  for index = 1, 3 do
    touchCheckpoint(first, index)
  end
  local messages = env:messageCount("ObbyProgress", first)
  touchCheckpoint(first, 3)
  expect(env:messageCount("ObbyProgress", first) == messages, "duplicate checkpoint emits nothing")
  touchCheckpoint(first, 2)
  expect(first:GetAttribute("Checkpoint") == 3, "old checkpoint cannot regress")
  env:advance(2)
  root(first).CFrame = CF.new(0, -100, 0)
  local acceptedAt = env.time
  service.assists:fail(first, "fall")
  env:advance(0.05)
  expect((root(first).Position - service.world.stages[3].safeSpawn.Position).Magnitude < 0.01, "fall rescue target")
  expect(env.time - acceptedAt <= 0.051, "headless rescue dispatch latency")
  env:advance(1.1)
  env:call(env.game.ReplicatedStorage.SharedEvents.Assistance, first, "Reset")
  expect((root(first).Position - service.world.stages[3].safeSpawn.Position).Magnitude < 0.01, "Reset target")
  for _ = 1, 3 do
    env:advance(1.1)
    env:call(env.game.ReplicatedStorage.SharedEvents.Assistance, first, "Reset")
  end
  expect(service.assists:snapshot(first).help, "fifth failure offers help")
  env:advance(1.1)
  env:call(env.game.ReplicatedStorage.SharedEvents.Assistance, first, "Help")
  expect(first:GetAttribute("Checkpoint") == 4, "opt-in help advances one chapter")
  expect(service.checkpoints:getProfile(first).assistedChapters["4"], "assistance recorded")
  local key = service.world.stages[1].model:FindFirstChild("GoldenKey", true)
  local keyId = key:GetAttribute("KeyId")
  for _, player in ipairs(players) do
    expect(service.checkpoints:markKey(player, keyId), "independent key claim")
    expect(not service.checkpoints:markKey(player, keyId), "key claim dedupe")
  end
  expect(key.Parent ~= nil, "key remains for other players")
  for index = 5, 18 do
    touchCheckpoint(first, index)
  end
  expect(env:messageCount("FinaleSpotlight", first) == 1, "personal finale exactly once")
  if count > 1 then
    expect(env:messageCount("FinaleSpotlight", players[2]) == 0, "nonfinisher never receives finale")
  end
  local checkpoints = {}
  for _, player in ipairs(players) do
    checkpoints[player] = player:GetAttribute("Checkpoint")
  end
  service:rebuild(service.world.seed)
  env:advance(0.3)
  for _, player in ipairs(players) do
    expect(service.checkpoints:isLoaded(player), "rebuild attaches existing player")
    expect(player:GetAttribute("Checkpoint") == checkpoints[player], "rebuild retains checkpoint")
    expect(service.checkpoints:getProfile(player).collectedKeys[keyId], "rebuild retains key")
    env:spawnCharacter(player, 0.2)
  end
  env:advance(0.4)
  for _, player in ipairs(players) do
    local checkpoint = checkpoints[player]
    local expected = checkpoint > 0 and service.world.stages[checkpoint].safeSpawn
      or service.world.stages[1].entrance + V.new(0, 4, 0)
    expect((root(player).Position - expected.Position).Magnitude < 0.01, "CharacterAdded after rebuild retains hooks")
  end
  env:call(env.game.ReplicatedStorage.SharedEvents.SetRunMode, first, "TimeTrial")
  expect(
    first:GetAttribute("Checkpoint") == 0 and not service.runState:get(first).running,
    "timed replay waits at start"
  )
  root(first).CFrame = service.world.startGate.CFrame
  env:signal(service.world.startGate, "Touched"):Fire(root(first))
  expect(service.runState:get(first).running, "timed replay starts from supported bridge")
  for _, player in ipairs(players) do
    env:removePlayer(player)
  end
  expect(next(service.checkpoints.profiles) == nil, "leave clears profiles")
  expect(next(service.assists.states) == nil, "leave clears assistance")
  print(
    "HEADLESS lifecycle: "
      .. count
      .. " simulated players; late join, reset/fall/help, keys, checkpoint traversal, personal finale, rebuild, respawn and replay passed"
  )
end
print(string.format("HEADLESS elapsed %.3fs (host test runtime, not Roblox performance)", os.clock() - start))
