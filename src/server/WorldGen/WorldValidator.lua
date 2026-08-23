--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local WorldValidator = {}

local function overlaps(a, b)
  local delta = a.Position - b.Position
  local reach = (a.Size + b.Size) * 0.5
  return math.abs(delta.X) <= reach.X and math.abs(delta.Y) <= reach.Y and math.abs(delta.Z) <= reach.Z
end

function WorldValidator.validate(stages: { any }, totalStages: number): ({ string }, number)
  local errors = {}
  local ids = {}
  local checkpoints = {}
  local indexes = {}
  local previousExit = nil
  for expectedIndex, stage in ipairs(stages) do
    if stage.stageIndex ~= expectedIndex then
      table.insert(errors, string.format("stage order gap or duplicate near %d", stage.stageIndex or -1))
    end
    if type(stage.stageIndex) ~= "number" or indexes[stage.stageIndex] then
      table.insert(errors, string.format("duplicate or invalid stage index near %s", tostring(stage.stageIndex)))
    else
      indexes[stage.stageIndex] = true
    end
    if not stage.stageId then
      table.insert(errors, "stage missing stable stageId")
    elseif ids[stage.stageId] then
      table.insert(errors, "duplicate stage id: " .. stage.stageId)
    else
      ids[stage.stageId] = true
    end
    if not stage.checkpoint or not stage.checkpoint:IsA("BasePart") then
      table.insert(errors, string.format("stage %d missing checkpoint", stage.stageIndex or -1))
    else
      checkpoints[stage.stageIndex] = true
      if stage.checkpoint:GetAttribute("StageIndex") ~= stage.stageIndex then
        table.insert(errors, string.format("checkpoint %d has wrong stage index", stage.stageIndex))
      end
    end
    if not stage.entrance or not stage.exit then
      table.insert(errors, string.format("stage %d missing entrance or exit", stage.stageIndex or -1))
    end
    if not stage.safeSpawn or not stage.bounds or not stage.mechanics then
      table.insert(errors, string.format("stage %d missing build result fields", stage.stageIndex or -1))
    end
    if stage.bounds and (stage.bounds.X <= 0 or stage.bounds.Y <= 0 or stage.bounds.Z <= 0) then
      table.insert(errors, string.format("stage %d has invalid bounds", stage.stageIndex or -1))
    end
    if stage.checkpoint then
      if stage.checkpoint.Size.X < 4 or stage.checkpoint.Size.Z < 4 then
        table.insert(
          errors,
          string.format("stage %d checkpoint has insufficient standing room", stage.stageIndex or -1)
        )
      end
      if stage.safeSpawn then
        local spawnOffset = stage.safeSpawn.Position - stage.checkpoint.Position
        if math.abs(spawnOffset.X) > 2 or math.abs(spawnOffset.Z) > 2 or spawnOffset.Y < 2 then
          table.insert(errors, string.format("stage %d safe spawn is not above checkpoint", stage.stageIndex or -1))
        end
      end
      for _, hazard in ipairs(CollectionService:GetTagged("KillBrick")) do
        if hazard:IsDescendantOf(stage.model) and hazard:IsA("BasePart") and overlaps(stage.checkpoint, hazard) then
          table.insert(
            errors,
            string.format("stage %d checkpoint overlaps hazard %s", stage.stageIndex or -1, hazard.Name)
          )
        end
      end
    end
    if stage.entrance and stage.exit then
      local forwardDistance = stage.exit.Position.X - stage.entrance.Position.X
      if forwardDistance <= 0 then
        table.insert(errors, string.format("stage %d does not progress forward", stage.stageIndex or -1))
      end
      if previousExit then
        local connector = (stage.entrance.Position - previousExit.Position).Magnitude
        if connector > GameConfig.StageSpacing.X then
          table.insert(errors, string.format("connector before stage %d is too long", stage.stageIndex or -1))
        end
      end
      previousExit = stage.exit
    end
    if not stage.model:GetAttribute("PrimaryMechanic") then
      table.insert(errors, string.format("stage %d missing presentation metadata", stage.stageIndex or -1))
    end
  end
  if #stages ~= totalStages then
    table.insert(errors, string.format("expected %d stages, found %d", totalStages, #stages))
  end
  for index = 1, totalStages do
    if not indexes[index] then
      table.insert(errors, "missing stage index " .. index)
    end
    if not checkpoints[index] then
      table.insert(errors, "missing checkpoint for stage " .. index)
    end
  end
  for _, key in ipairs(CollectionService:GetTagged("KeyCollectible")) do
    local keyId = key:GetAttribute("KeyId")
    if not keyId then
      table.insert(errors, "collectible missing KeyId: " .. key:GetFullName())
    elseif ids[keyId] then
      table.insert(errors, "duplicate collectible id: " .. keyId)
    else
      ids[keyId] = true
    end
  end
  for _, stage in ipairs(stages) do
    for _, descendant in ipairs(stage.model:GetDescendants()) do
      if descendant:IsA("BasePart") and not descendant.Anchored then
        local intentionalRide = descendant:FindFirstAncestorWhichIsA("Model")
        local isCartPart = intentionalRide and intentionalRide:FindFirstChild("Seat") ~= nil
        if not isCartPart then
          table.insert(errors, "unanchored environment part: " .. descendant:GetFullName())
        end
      end
    end
  end
  return errors, #stages
end

return WorldValidator
