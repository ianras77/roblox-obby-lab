-- selene: allow(incorrect_standard_library_use)
-- selene: allow(shadowing)
-- Executes production modules against explicit headless service adapters.
-- This is NOT Studio, engine physics, renderer, networking, or live backend proof.
local Environment = require("./Environment")
local process = require("@lune/process")
local env = Environment.new(process.args[1] or "/tmp/toads-production-playability.rbxlx")
local V, CF = env.roblox.Vector3, env.roblox.CFrame
local start = os.clock()
-- Record the bounded terrain operation; this adapter does NOT simulate voxels.
local terrain = env.instance.new("Terrain")
terrain.Parent = env.workspace
local ok, service = pcall(function()
  return env:require(env.game.ServerScriptService.Services.ObbyService).new()
end)
if not ok then
  for _, warning in ipairs(env.warnings) do
    print(warning)
  end
  error(service)
end
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
expect(#env.terrainClears == 1, "one bounded terrain reservation")
local reserved = env.terrainClears[1]
expect(reserved.material == env.roblox.Enum.Material.Air and reserved.size.Z == 112, "terrain reservation dimensions")
expect(reserved.size.X < 2200 and reserved.size.Y < 100, "terrain reservation stays bounded")
expect(service.world.model.SpawnPad.CFrame.LookVector:Dot(V.zAxis) > 0.99, "spawn faces bridge")
for _, stage in ipairs(service.world.stages) do
  expect(stage.safeSpawn.LookVector:Dot(V.xAxis) > 0.99, "checkpoint faces travel")
end
-- Direct endpoint checks catch a mirrored/inverted ramp basis independently of rays.
for _, part in ipairs(service.world.model:GetDescendants()) do
  if part:IsA("BasePart") and (part.Name == "ScenicConnector" or part.Name == "CatchRamp") then
    expect(part.CFrame.RightVector.Y >= -0.001, "ramp rises toward the destination")
    expect(part.CFrame.UpVector.Y > 0.98, "gentle recovery and transition slopes")
  end
end
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
local firstStage = service.world.stages[1]
local ramp = firstStage.model:FindFirstChild("CatchRamp", true)
local rampParent = ramp.Parent
ramp.Parent = nil
expect(not pcall(validate), "missing recovery ramp must fail even above catch floor")
ramp.Parent = rampParent
local savedSpawn = firstStage.safeSpawn
firstStage.safeSpawn = CF.new(savedSpawn.Position)
expect(not pcall(validate), "wrong respawn direction must fail")
firstStage.safeSpawn = savedSpawn
local blocker = env.instance.new("Part")
blocker.Name = "ImportedMountainProbe"
blocker.Anchored = true
blocker.Size = V.new(4, 10, 20)
blocker.CFrame = firstStage.entrance * CF.new(40, 6, 0)
blocker.Parent = env.workspace
expect(not pcall(validate), "external obstacle BETWEEN route nodes must fail")
blocker.CFrame = firstStage.entrance * CF.new(40, 10, 0)
blocker.Size = V.new(20, 2, 20)
expect(not pcall(validate), "overhead obstruction must fail")
blocker:Destroy()
validate()
print(
  "HEADLESS geometry: 18 stages; missing support/ramp, external mountain/ceiling, wrong orientation and controller mutations passed"
)

for _, count in ipairs({ 1, 2, 8 }) do
  local players = {}
  for index = 1, count do
    players[index] = env:addPlayer(count * 100 + index, index == count and 0.2 or nil)
  end
  env:advance(0.4)
  for _, player in ipairs(players) do
    expect(service.checkpoints:isLoaded(player), "late join/profile load")
    expect(root(player) ~= nil, "delayed character root")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    expect(
      humanoid.WalkSpeed == 16 and math.abs(humanoid.JumpHeight - 7.2) < 0.001 and not humanoid.UseJumpPower,
      "authored movement baseline"
    )
    expect(root(player).CFrame.LookVector:Dot(V.xAxis) > 0.99, "new player faces chapter one")
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
  local humanoid = first.Character:FindFirstChildOfClass("Humanoid")
  humanoid.Sit = true
  service.checkpoints:teleportToSavedCheckpoint(first)
  expect(not humanoid.Sit, "cart passenger released before recovery")
  expect(root(first).CFrame.LookVector:Dot(V.xAxis) > 0.99, "saved respawn faces next chapter")
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
