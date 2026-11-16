local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Definitions = require(game:GetService("ReplicatedStorage").Config.StageDefinitions)
local RouteValidator = {}
local transformTags =
  { "MovingPlatform", "Rotator", "BossGavel", "Beacon", "VisualBob", "Lava", "Cart", "FallingPlatform" }
function RouteValidator.assertWorld(stages, root, spawn)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances = { root }
  params.RespectCanCollide = true
  local function supported(position, id, required)
    local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0), params)
    assert(hit and hit.Instance.Anchored and hit.Instance.CanCollide, id .. ": missing stable support")
    if required then
      assert(
        hit.Instance:GetAttribute("RequiredSupport") or CollectionService:HasTag(hit.Instance, "Checkpoint"),
        id .. ": required support replaced by " .. hit.Instance:GetFullName()
      )
    end
  end
  -- Include the actual workspace, not just generated parts: imported mountains,
  -- roofs and terrain can obstruct a perfectly supported route. Ignore players
  -- during rebuilds so a visitor cannot invalidate the world.
  local clearance = RaycastParams.new()
  clearance.FilterType = Enum.RaycastFilterType.Exclude
  local characters = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
      table.insert(characters, player.Character)
    end
  end
  clearance.FilterDescendantsInstances = characters
  clearance.RespectCanCollide = true
  local function clear(position, id)
    local hit = workspace:Raycast(position + Vector3.new(0, 1.1, 0), Vector3.new(0, 12, 0), clearance)
    assert(not hit, id .. ": blocked walking/jump clearance by " .. (hit and hit.Instance:GetFullName() or "?"))
  end
  local function clearStrip(a, b, width, id)
    local delta = b - a
    local side = Vector3.new(-delta.Z, 0, delta.X).Unit
    local count = math.max(1, math.ceil(delta.Magnitude / 2))
    for step = 0, count do
      for _, offset in ipairs({ -width / 2 + 2, 0, width / 2 - 2 }) do
        clear(a:Lerp(b, step / count) + side * offset, id)
      end
    end
  end
  supported(spawn.Position, "spawn")
  clear(spawn.Position, "spawn")
  local previous = spawn.CFrame
  for index, stage in ipairs(stages) do
    local id = stage.stageId
    local definition = Definitions[index]
    assert(stage.finish and stage.checkpoint.Size.X >= 10 and stage.checkpoint.Size.Z >= 10, id .. ": finish landing")
    supported(stage.entrance.Position, id)
    supported(stage.exit.Position, id)
    supported(stage.checkpoint.Position, id)
    assert(stage.safeSpawn.LookVector:Dot(stage.entrance.RightVector) > 0.99, id .. ": respawn faces off route")
    clearStrip(stage.entrance.Position, stage.exit.Position, 10, id)
    -- Every fall has three visible low ramps back to a broad landing.
    for _, x in ipairs({ 16, 48, 80 }) do
      local a = (stage.entrance * CFrame.new(x, -2, -19)).Position
      local b = (stage.entrance * CFrame.new(x, 0, -7)).Position
      for step = 0, 12 do
        local position = a:Lerp(b, step / 12)
        supported(position, id .. " recovery ramp", true)
        clear(position, id .. " recovery ramp")
      end
    end
    assert(#stage.mainPathNodes >= 3, id .. ": missing main path")
    for n, node in ipairs(stage.mainPathNodes) do
      supported(node.cframe.Position, id, true)
      for _, x in ipairs({ -0.4, 0.4 }) do
        for _, z in ipairs({ -0.4, 0.4 }) do
          supported(
            (node.cframe * CFrame.new(x * node.width, 0, z * node.depth)).Position,
            id .. " landing footprint",
            true
          )
        end
      end
      if n > 1 then
        local before = stage.mainPathNodes[n - 1]
        assert(
          (node.cframe.Position - before.cframe.Position).Magnitude - (node.width + before.width) / 2
            <= definition.path.maxGap,
          id .. ": gap budget"
        )
        assert(math.abs(node.cframe.Y - before.cframe.Y) <= 4, id .. ": vertical step")
      end
      for _, hazard in ipairs(CollectionService:GetTagged("KillBrick")) do
        if hazard:IsDescendantOf(root) then
          local localPoint = hazard.CFrame:PointToObjectSpace(node.cframe.Position + Vector3.new(0, 3, 0))
          local half = hazard.Size / 2 + Vector3.new(2, 3, 2)
          assert(
            math.abs(localPoint.X) > half.X or math.abs(localPoint.Y) > half.Y or math.abs(localPoint.Z) > half.Z,
            id .. ": required node in lethal volume"
          )
          assert(
            (hazard.Position - stage.safeSpawn.Position).Magnitude - hazard.Size.Magnitude / 2 >= 12,
            id .. ": unsafe checkpoint window"
          )
        end
      end
    end
    local delta = stage.entrance.Position - previous.Position
    assert(
      math.abs(delta.Y) / math.max(1, Vector3.new(delta.X, 0, delta.Z).Magnitude) <= 0.3,
      id .. ": steep connector"
    )
    if delta.Magnitude > 0.01 then
      clearStrip(previous.Position, stage.entrance.Position, 10, id .. " connector")
    end
    for step = 0, math.ceil(delta.Magnitude) do
      supported(
        previous.Position:Lerp(stage.entrance.Position, step / math.max(1, math.ceil(delta.Magnitude))),
        id .. " connector"
      )
    end
    for _, part in ipairs(stage.model:GetDescendants()) do
      if part:IsA("BasePart") then
        local controllers = 0
        for _, tag in ipairs(transformTags) do
          if CollectionService:HasTag(part, tag) then
            controllers += 1
          end
        end
        assert(controllers <= 1, id .. ": conflicting transform controllers " .. part.Name)
        assert(not (CollectionService:HasTag(part, "VisualBob") and not part.Anchored), id .. ": unanchored visual")
        assert(not (CollectionService:HasTag(part, "Laser") and part.CanCollide), id .. ": collidable laser")
        assert(
          not part:GetAttribute("RequiresPurchase")
            and not part:GetAttribute("RequiresCoop")
            and not part:GetAttribute("RequiresCollectible")
            and not part:GetAttribute("HiddenRequired"),
          id .. ": forbidden dependency"
        )
      end
    end
    previous = stage.exit
  end
end
return RouteValidator
