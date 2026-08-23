--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local WorldValidator = {}

local function finite(value)
  return value == value and math.abs(value) < math.huge
end

local function finiteVector(vector)
  return finite(vector.X) and finite(vector.Y) and finite(vector.Z)
end

local function overlaps(a, b)
  local delta = a.Position - b.Position
  local reach = (a.Size + b.Size) * 0.5
  return math.abs(delta.X) <= reach.X and math.abs(delta.Y) <= reach.Y and math.abs(delta.Z) <= reach.Z
end

local function stageLabel(stage)
  return tostring(stage and stage.stageIndex or "?")
end

function WorldValidator.validate(stages: { any }, totalStages: number): ({ string }, number)
  local errors = {}
  local ids = {}
  local checkpoints = {}
  local indexes = {}
  local previousExit = nil
  for expectedIndex, stage in ipairs(stages) do
    local stageModel = stage.model
    local modelIsModel = typeof(stageModel) == "Instance" and stageModel:IsA("Model")
    local checkpointIsPart = typeof(stage.checkpoint) == "Instance" and stage.checkpoint:IsA("BasePart")
    if stage.stageIndex ~= expectedIndex then
      table.insert(errors, string.format("stage order gap or duplicate near %s", stageLabel(stage)))
    end
    if
      type(stage.stageIndex) ~= "number"
      or not finite(stage.stageIndex)
      or stage.stageIndex % 1 ~= 0
      or indexes[stage.stageIndex]
    then
      table.insert(errors, string.format("duplicate or invalid stage index near %s", tostring(stage.stageIndex)))
    else
      indexes[stage.stageIndex] = true
    end
    if type(stage.stageId) ~= "string" or #stage.stageId == 0 or #stage.stageId > 80 then
      table.insert(errors, "stage missing stable stageId")
    elseif ids[stage.stageId] then
      table.insert(errors, "duplicate stage id: " .. stage.stageId)
    else
      ids[stage.stageId] = true
    end
    if not checkpointIsPart then
      table.insert(errors, string.format("stage %s missing checkpoint", stageLabel(stage)))
    else
      checkpoints[stage.stageIndex] = true
      if stage.checkpoint:GetAttribute("StageIndex") ~= stage.stageIndex then
        table.insert(errors, string.format("checkpoint %d has wrong stage index", stage.stageIndex))
      end
    end
    local validEntrance = typeof(stage.entrance) == "CFrame"
    local validExit = typeof(stage.exit) == "CFrame"
    local validSafeSpawn = typeof(stage.safeSpawn) == "CFrame"
    local validConnectorLength = type(stage.connectorLength) == "number" and finite(stage.connectorLength)
    local validZoneModel = typeof(stage.zoneModel) == "Instance" and stage.zoneModel:IsA("Model")
    local corridor = stage.pathCorridor
    local validCorridor = type(corridor) == "table"
      and typeof(corridor.center) == "CFrame"
      and type(corridor.width) == "number"
      and finite(corridor.width)
      and corridor.width > 0
    local validMechanics = type(stage.mechanics) == "table" and #stage.mechanics > 0
    if validMechanics then
      for _, mechanic in ipairs(stage.mechanics) do
        if type(mechanic) ~= "string" or #mechanic == 0 or #mechanic > 80 then
          validMechanics = false
          break
        end
      end
    end
    if not validEntrance or not validExit then
      table.insert(errors, string.format("stage %s missing entrance or exit", stageLabel(stage)))
    end
    if not validSafeSpawn or typeof(stage.bounds) ~= "Vector3" or not validMechanics then
      table.insert(errors, string.format("stage %s missing build result fields", stageLabel(stage)))
    end
    if not validConnectorLength or stage.connectorLength < 0 then
      table.insert(errors, string.format("stage %s has invalid connector length", stageLabel(stage)))
    end
    if not validZoneModel then
      table.insert(errors, string.format("stage %s is missing a valid zone model", stageLabel(stage)))
    end
    if not validCorridor then
      table.insert(errors, string.format("stage %s is missing a valid path corridor", stageLabel(stage)))
    end
    local expectedZone = type(stage.stageIndex) == "number" and math.ceil(stage.stageIndex / GameConfig.StagesPerZone)
      or nil
    if stage.zoneIndex ~= expectedZone then
      table.insert(errors, string.format("stage %s has incorrect zone ownership", stageLabel(stage)))
    end
    if modelIsModel and stageModel:GetAttribute("ZoneIndex") ~= expectedZone then
      table.insert(errors, string.format("stage %s model is outside its expected zone", stageLabel(stage)))
    end
    if modelIsModel and validZoneModel and stageModel.Parent ~= stage.zoneModel then
      table.insert(errors, string.format("stage %s is not parented to its zone model", stageLabel(stage)))
    end
    if
      stage.bounds
      and (not finiteVector(stage.bounds) or stage.bounds.X <= 0 or stage.bounds.Y <= 0 or stage.bounds.Z <= 0)
    then
      table.insert(errors, string.format("stage %s has invalid bounds", stageLabel(stage)))
    end
    if validEntrance and not finiteVector(stage.entrance.Position) then
      table.insert(errors, string.format("stage %s has invalid entrance position", stageLabel(stage)))
    end
    if validExit and not finiteVector(stage.exit.Position) then
      table.insert(errors, string.format("stage %s has invalid exit position", stageLabel(stage)))
    end
    if validSafeSpawn and not finiteVector(stage.safeSpawn.Position) then
      table.insert(errors, string.format("stage %s has invalid safe spawn position", stageLabel(stage)))
    end
    if stage.checkpoint and stage.checkpoint:IsA("BasePart") then
      if stage.checkpoint.Size.X < 4 or stage.checkpoint.Size.Z < 4 then
        table.insert(errors, string.format("stage %s checkpoint has insufficient standing room", stageLabel(stage)))
      end
      if stage.safeSpawn then
        local spawnOffset = stage.safeSpawn.Position - stage.checkpoint.Position
        if math.abs(spawnOffset.X) > 2 or math.abs(spawnOffset.Z) > 2 or spawnOffset.Y < 2 then
          table.insert(errors, string.format("stage %s safe spawn is not above checkpoint", stageLabel(stage)))
        end
      end
      if modelIsModel then
        for _, hazard in ipairs(CollectionService:GetTagged("KillBrick")) do
          if hazard:IsDescendantOf(stageModel) and hazard:IsA("BasePart") and overlaps(stage.checkpoint, hazard) then
            table.insert(
              errors,
              string.format("stage %s checkpoint overlaps hazard %s", stageLabel(stage), hazard.Name)
            )
          end
        end
      end
    end
    if validEntrance and validExit then
      local forwardDistance = stage.exit.Position.X - stage.entrance.Position.X
      if forwardDistance <= 0 then
        table.insert(errors, string.format("stage %s does not progress forward", stageLabel(stage)))
      end
      if previousExit then
        local connector = (stage.entrance.Position - previousExit.Position).Magnitude
        if not validConnectorLength or math.abs(stage.connectorLength - connector) > 0.01 then
          table.insert(errors, string.format("connector before stage %s is not measured correctly", stageLabel(stage)))
        elseif connector > GameConfig.StageSpacing.X then
          table.insert(errors, string.format("connector before stage %s is too long", stageLabel(stage)))
        end
      elseif validConnectorLength and stage.connectorLength > 0.01 then
        table.insert(errors, string.format("first stage %s has a nonzero connector", stageLabel(stage)))
      end
      previousExit = stage.exit
    end
    if not modelIsModel then
      table.insert(errors, string.format("stage %s missing model", stageLabel(stage)))
    elseif not stageModel:GetAttribute("PrimaryMechanic") then
      table.insert(errors, string.format("stage %s missing presentation metadata", stageLabel(stage)))
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
    local owned = false
    for _, stage in ipairs(stages) do
      if stage.model and typeof(stage.model) == "Instance" and key:IsDescendantOf(stage.model) then
        owned = true
        break
      end
    end
    if owned then
      local keyId = key:GetAttribute("KeyId")
      if not keyId then
        table.insert(errors, "collectible missing KeyId: " .. key:GetFullName())
      elseif ids[keyId] then
        table.insert(errors, "duplicate collectible id: " .. keyId)
      else
        ids[keyId] = true
      end
    end
  end
  for _, stage in ipairs(stages) do
    if typeof(stage.model) == "Instance" and stage.model:IsA("Model") then
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
  end
  return errors, #stages
end

return WorldValidator
