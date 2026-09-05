local CollectionService = game:GetService("CollectionService")
local Definitions = require(game:GetService("ReplicatedStorage").Config.StageDefinitions)
local RouteValidator = {}
local transformTags =
  { "MovingPlatform", "Rotator", "BossGavel", "Beacon", "VisualBob", "Lava", "Cart", "FallingPlatform" }
function RouteValidator.assertWorld(stages, root, spawn)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances = { root }
  params.RespectCanCollide = true
  local function supported(position, id)
    local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0), params)
    assert(hit and hit.Instance.Anchored and hit.Instance.CanCollide, id .. ": missing stable support")
  end
  supported(spawn.Position, "spawn")
  local previous = spawn.CFrame
  for index, stage in ipairs(stages) do
    local id = stage.stageId
    local definition = Definitions[index]
    assert(stage.finish and stage.checkpoint.Size.X >= 10 and stage.checkpoint.Size.Z >= 10, id .. ": finish landing")
    supported(stage.entrance.Position, id)
    supported(stage.exit.Position, id)
    supported(stage.checkpoint.Position, id)
    assert(#stage.mainPathNodes >= 3, id .. ": missing main path")
    for n, node in ipairs(stage.mainPathNodes) do
      supported(node.cframe.Position, id)
      for _, x in ipairs({ -0.4, 0.4 }) do
        for _, z in ipairs({ -0.4, 0.4 }) do
          supported((node.cframe * CFrame.new(x * node.width, 0, z * node.depth)).Position, id .. " landing footprint")
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
