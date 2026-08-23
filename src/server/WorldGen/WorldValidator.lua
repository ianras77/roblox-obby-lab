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
    if not checkpointIsPart then
      table.insert(errors, string.format("stage %d missing checkpoint", stage.stageIndex or -1))
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
    if not validEntrance or not validExit then
      table.insert(errors, string.format("stage %d missing entrance or exit", stage.stageIndex or -1))
    end
    if not validSafeSpawn or typeof(stage.bounds) ~= "Vector3" or type(stage.mechanics) ~= "table" then
      table.insert(errors, string.format("stage %d missing build result fields", stage.stageIndex or -1))
    end
    if not validConnectorLength or stage.connectorLength < 0 then
      table.insert(errors, string.format("stage %d has invalid connector length", stage.stageIndex or -1))
    end
    if not validZoneModel then
      table.insert(errors, string.format("stage %d is missing a valid zone model", stage.stageIndex or -1))
    end
    local expectedZone = type(stage.stageIndex) == "number" and math.ceil(stage.stageIndex / GameConfig.StagesPerZone)
      or nil
    if stage.zoneIndex ~= expectedZone then
      table.insert(errors, string.format("stage %d has incorrect zone ownership", stage.stageIndex or -1))
    end
    if modelIsModel and stageModel:GetAttribute("ZoneIndex") ~= expectedZone then
      table.insert(errors, string.format("stage %d model is outside its expected zone", stage.stageIndex or -1))
    end
    if modelIsModel and validZoneModel and stageModel.Parent ~= stage.zoneModel then
      table.insert(errors, string.format("stage %d is not parented to its zone model", stage.stageIndex or -1))
    end
    if
      stage.bounds
      and (not finiteVector(stage.bounds) or stage.bounds.X <= 0 or stage.bounds.Y <= 0 or stage.bounds.Z <= 0)
    then
      table.insert(errors, string.format("stage %d has invalid bounds", stage.stageIndex or -1))
    end
    if validEntrance and not finiteVector(stage.entrance.Position) then
      table.insert(errors, string.format("stage %d has invalid entrance position", stage.stageIndex or -1))
    end
    if validExit and not finiteVector(stage.exit.Position) then
      table.insert(errors, string.format("stage %d has invalid exit position", stage.stageIndex or -1))
    end
    if validSafeSpawn and not finiteVector(stage.safeSpawn.Position) then
      table.insert(errors, string.format("stage %d has invalid safe spawn position", stage.stageIndex or -1))
    end
    if stage.checkpoint and stage.checkpoint:IsA("BasePart") then
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
      if modelIsModel then
        for _, hazard in ipairs(CollectionService:GetTagged("KillBrick")) do
          if hazard:IsDescendantOf(stageModel) and hazard:IsA("BasePart") and overlaps(stage.checkpoint, hazard) then
            table.insert(
              errors,
              string.format("stage %d checkpoint overlaps hazard %s", stage.stageIndex or -1, hazard.Name)
            )
          end
        end
      end
    end
    if validEntrance and validExit then
      local forwardDistance = stage.exit.Position.X - stage.entrance.Position.X
      if forwardDistance <= 0 then
        table.insert(errors, string.format("stage %d does not progress forward", stage.stageIndex or -1))
      end
      if previousExit then
        local connector = (stage.entrance.Position - previousExit.Position).Magnitude
        if not validConnectorLength or math.abs(stage.connectorLength - connector) > 0.01 then
          table.insert(
            errors,
            string.format("connector before stage %d is not measured correctly", stage.stageIndex or -1)
          )
        elseif connector > GameConfig.StageSpacing.X then
          table.insert(errors, string.format("connector before stage %d is too long", stage.stageIndex or -1))
        end
      elseif validConnectorLength and stage.connectorLength > 0.01 then
        table.insert(errors, string.format("first stage %d has a nonzero connector", stage.stageIndex or -1))
      end
      previousExit = stage.exit
    end
    if not modelIsModel then
      table.insert(errors, string.format("stage %d missing model", stage.stageIndex or -1))
    elseif not stageModel:GetAttribute("PrimaryMechanic") then
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
