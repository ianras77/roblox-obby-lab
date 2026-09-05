-- Run from the SERVER command bar in studio-test.project.json after Play:
-- require(game.ServerStorage.PlayabilityHarness).run()
-- This deliberately manipulates test players and must never run in a published server.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Harness = {}
function Harness.run()
  assert(RunService:IsStudio(), "Studio only")
  local service = require(game.ServerScriptService.Services.ObbyService).new()
  local validator = require(game.ServerScriptService.WorldGen.RouteValidator)
  local Build = require(game.ReplicatedStorage.Util.Build)
  local part = Build.part({
    Name = "PropertyProbe",
    Transparency = 0.6,
    CanCollide = false,
    CanTouch = false,
    CanQuery = false,
    CastShadow = false,
    Massless = true,
    Shape = Enum.PartType.Ball,
  })
  assert(
    part.Transparency == 0.6
      and not part.CanCollide
      and not part.CanTouch
      and not part.CanQuery
      and part.Massless
      and not part.CastShadow
      and part.Shape == Enum.PartType.Ball,
    "Build properties applied"
  )
  part:Destroy()
  assert(not pcall(function()
    Build.part({ Misspelled = true })
  end), "unsupported property rejected")
  validator.assertWorld(service.world.stages, service.world.model, service.world.model.SpawnPad)
  local CollectionService = game:GetService("CollectionService")
  local probe = service.world.stages[1].model:FindFirstChild("MainPath_4", true)
  local originalParent = probe.Parent
  probe.Parent = nil
  assert(not pcall(function()
    validator.assertWorld(service.world.stages, service.world.model, service.world.model.SpawnPad)
  end), "missing support detected")
  probe.Parent = originalParent
  CollectionService:AddTag(probe, "MovingPlatform")
  CollectionService:AddTag(probe, "Rotator")
  assert(not pcall(function()
    validator.assertWorld(service.world.stages, service.world.model, service.world.model.SpawnPad)
  end), "controller conflict detected")
  CollectionService:RemoveTag(probe, "MovingPlatform")
  CollectionService:RemoveTag(probe, "Rotator")
  local players = Players:GetPlayers()
  assert(#players > 0, "start 1, 2, or 8 clients first")
  for _, player in ipairs(players) do
    local deadline = os.clock() + 8
    while not service.checkpoints:isLoaded(player) and os.clock() < deadline do
      task.wait(0.1)
    end
    assert(service.checkpoints:isLoaded(player), "late join load")
    service.checkpoints:resetForAdventure(player)
    local root = player.Character and player.Character:WaitForChild("HumanoidRootPart", 5)
    assert(root, "character root")
    for index, stage in ipairs(service.world.stages) do
      service.checkpoints:teleportToCFrame(player, stage.safeSpawn)
      service.checkpoints:onCheckpointTouched(index, stage.checkpoint, root)
      assert(player:GetAttribute("Checkpoint") == index, "traverse " .. index)
      service.checkpoints:onCheckpointTouched(index, stage.checkpoint, root)
      assert(player:GetAttribute("Checkpoint") == index, "duplicate touch")
      if index > 1 then
        local earlier = service.world.stages[index - 1]
        service.checkpoints:onCheckpointTouched(index - 1, earlier.checkpoint, root)
        assert(player:GetAttribute("Checkpoint") == index, "no regression")
      end
    end
    local start = os.clock()
    service.checkpoints:teleportToSavedCheckpoint(player)
    assert(os.clock() - start < 2, "recovery call budget")
    assert((root.Position - service.world.stages[18].safeSpawn.Position).Magnitude < 1, "recovery destination")
  end
  if #players >= 2 then
    local id = "harness_personal_key"
    assert(service.checkpoints:markKey(players[1], id), "first claim")
    assert(service.checkpoints:markKey(players[2], id), "second independent claim")
    assert(not service.checkpoints:markKey(players[1], id), "claim dedupe")
  end
  local expected = {}
  for _, player in ipairs(players) do
    expected[player] = player:GetAttribute("Checkpoint")
  end
  service:rebuild(service.world.seed)
  task.wait(1)
  for _, player in ipairs(players) do
    assert(service.checkpoints:isLoaded(player), "rebuild attached")
    assert(player:GetAttribute("Checkpoint") == expected[player], "rebuild retains session")
  end
  validator.assertWorld(service.world.stages, service.world.model, service.world.model.SpawnPad)
  print(
    "STUDIO HARNESS PASS: geometry, properties, traversal, monotonicity, recovery, personal claims, rebuild; clients="
      .. #players
  )
  print(
    "Still manual: movement feel, real respawn latency, finale isolation, devices, gamepad, network simulation, profiling, human fun."
  )
end
return Harness
