--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("StageConfig"))
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))
local PlayabilityConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("PlayabilityConfig"))

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

local function validateZones(zones, totalZones, root)
  local errors = {}
  if type(zones) ~= "table" or #zones ~= totalZones then
    table.insert(
      errors,
      string.format("expected %s zones, found %s", tostring(totalZones), tostring(zones and #zones or 0))
    )
    return errors
  end
  local previousExit = nil
  for expectedIndex, zone in ipairs(zones) do
    local modelIsModel = typeof(zone.model) == "Instance" and zone.model:IsA("Model")
    if zone.zoneIndex ~= expectedIndex then
      table.insert(errors, string.format("zone order gap or duplicate near %s", tostring(zone.zoneIndex)))
    end
    if not modelIsModel or zone.model.Parent ~= root then
      table.insert(errors, string.format("zone %s is not owned by generated root", tostring(zone.zoneIndex)))
    end
    if typeof(zone.entrance) ~= "CFrame" or typeof(zone.exit) ~= "CFrame" then
      table.insert(errors, string.format("zone %s has invalid entrance or exit", tostring(zone.zoneIndex)))
    elseif not finiteVector(zone.entrance.Position) or not finiteVector(zone.exit.Position) then
      table.insert(errors, string.format("zone %s has non-finite entrance or exit", tostring(zone.zoneIndex)))
    end
    if typeof(zone.center) ~= "Vector3" or not finiteVector(zone.center) then
      table.insert(errors, string.format("zone %s has invalid center", tostring(zone.zoneIndex)))
    end
    if
      typeof(zone.bounds) ~= "Vector3"
      or not finiteVector(zone.bounds)
      or zone.bounds.X <= 0
      or zone.bounds.Y <= 0
      or zone.bounds.Z <= 0
    then
      table.insert(errors, string.format("zone %s has invalid bounds", tostring(zone.zoneIndex)))
    end
    if previousExit and typeof(zone.entrance) == "CFrame" then
      if (zone.entrance.Position - previousExit.Position).Magnitude > GameConfig.StageSpacing.X then
        table.insert(errors, string.format("zone %s entrance transition is too long", tostring(zone.zoneIndex)))
      end
    end
    if typeof(zone.exit) == "CFrame" then
      previousExit = zone.exit
    end
  end
  return errors
end

local function validateRoot(root)
  local errors = {}
  if typeof(root) ~= "Instance" or not root:IsA("Model") then
    table.insert(errors, "generated root is missing or invalid")
    return errors
  end
  if root.Parent ~= workspace then
    table.insert(errors, "generated root is not parented to Workspace")
  end
  if root:GetAttribute("GeneratorOwner") ~= "ToadsGreatEscape" then
    table.insert(errors, "generated root has invalid owner")
  end
  if root:GetAttribute("GeneratorVersion") ~= WorldGenConfig.GeneratorVersion then
    table.insert(errors, "generated root has unsupported generator version")
  end
  local seed = root:GetAttribute("Seed")
  if type(seed) ~= "number" or not finite(seed) or seed % 1 ~= 0 or seed < 0 or seed > GameConfig.MaxDevSeed then
    table.insert(errors, "generated root has an invalid seed")
  end
  return errors
end

function WorldValidator.validate(
  stages: { any },
  totalStages: number,
  zones: { any }?,
  root: Instance?
): ({ string }, number)
  local errors = {}
  for _, rootError in ipairs(validateRoot(root)) do
    table.insert(errors, rootError)
  end
  if zones then
    for _, zoneError in ipairs(validateZones(zones, GameConfig.Zones, root)) do
      table.insert(errors, zoneError)
    end
  end
  local ids = {}
  local checkpoints = {}
  local indexes = {}
  local previousExit = nil
  for expectedIndex, stage in ipairs(stages) do
    local stageModel = stage.model
    local modelIsModel = typeof(stageModel) == "Instance" and stageModel:IsA("Model")
    local checkpointIsPart = typeof(stage.checkpoint) == "Instance" and stage.checkpoint:IsA("BasePart")
    local validStageIndex = type(stage.stageIndex) == "number"
      and finite(stage.stageIndex)
      and stage.stageIndex % 1 == 0
    local definition = validStageIndex and StageConfig.getByIndex(stage.stageIndex) or nil
    if not definition or type(definition.requiredRoute) ~= "table" or #definition.requiredRoute < 3 then
      table.insert(errors, string.format("stage %s missing required Adventure route", stageLabel(stage)))
    else
      for _, waypoint in ipairs(definition.requiredRoute) do
        if
          type(waypoint.id) ~= "string"
          or typeof(waypoint.localPosition) ~= "Vector3"
          or typeof(waypoint.minLandingSize) ~= "Vector2"
        then
          table.insert(errors, string.format("stage %s has malformed required route", stageLabel(stage)))
          break
        end
        if waypoint.minLandingSize.X < 7 or waypoint.minLandingSize.Y < 7 then
          table.insert(errors, string.format("stage %s required landing below size floor", stageLabel(stage)))
        end
      end
    end
    if stage.stageIndex ~= expectedIndex then
      table.insert(errors, string.format("stage order gap or duplicate near %s", stageLabel(stage)))
    end
    if not validStageIndex or indexes[stage.stageIndex] then
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
    if not definition or stage.stageId ~= definition.id then
      table.insert(
        errors,
        string.format("stage %s stable ID does not match canonical configuration", stageLabel(stage))
      )
    end
    if not definition or stage.stageType ~= WorldGenConfig.StageTypes[definition.index] then
      table.insert(errors, string.format("stage %s type does not match canonical configuration", stageLabel(stage)))
    end
    if not checkpointIsPart then
      table.insert(errors, string.format("stage %s missing checkpoint", stageLabel(stage)))
    else
      checkpoints[stage.stageIndex] = true
      if not modelIsModel or not stage.checkpoint:IsDescendantOf(stageModel) then
        table.insert(errors, string.format("stage %s checkpoint is outside its model", stageLabel(stage)))
      end
      if stage.checkpoint:GetAttribute("StageIndex") ~= stage.stageIndex then
        table.insert(errors, string.format("checkpoint %d has wrong stage index", stage.stageIndex))
      end
      if stage.checkpoint:GetAttribute("StageId") ~= stage.stageId then
        table.insert(errors, string.format("checkpoint %d has wrong stable stage ID", stage.stageIndex))
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
    if modelIsModel then
      if stageModel:GetAttribute("StageId") ~= stage.stageId then
        table.insert(errors, string.format("stage %s model ID differs from manifest", stageLabel(stage)))
      end
      if stageModel:GetAttribute("StageIndex") ~= stage.stageIndex then
        table.insert(errors, string.format("stage %s model index differs from manifest", stageLabel(stage)))
      end
    end
    if modelIsModel and validZoneModel and stageModel.Parent ~= stage.zoneModel then
      table.insert(errors, string.format("stage %s is not parented to its zone model", stageLabel(stage)))
    end
    if
      stage.bounds
      and (
        typeof(stage.bounds) ~= "Vector3"
        or not finiteVector(stage.bounds)
        or stage.bounds.X <= 0
        or stage.bounds.Y <= 0
        or stage.bounds.Z <= 0
      )
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
    if checkpointIsPart then
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
    if modelIsModel then
      for _, descendant in ipairs(stageModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
          if CollectionService:HasTag(descendant, "Conveyor") and descendant:GetAttribute("Direction") == nil then
            table.insert(errors, string.format("stage %s conveyor lacks direction", stageLabel(stage)))
          elseif CollectionService:HasTag(descendant, "MovingPlatform") then
            local amplitude = math.abs(descendant:GetAttribute("Amplitude") or 10)
            local period = descendant:GetAttribute("PeriodSeconds")
            if type(period) ~= "number" or period <= 0 then
              table.insert(errors, string.format("stage %s moving platform lacks PeriodSeconds", stageLabel(stage)))
            elseif amplitude * 2 * math.pi / period > PlayabilityConfig.Limits.MovingPlatformPeakVelocity then
              table.insert(
                errors,
                string.format("stage %s moving platform exceeds peak velocity cap", stageLabel(stage))
              )
            end
          elseif CollectionService:HasTag(descendant, "FallingPlatform") then
            local delay = descendant:GetAttribute("DropDelay")
            if type(delay) ~= "number" or delay < PlayabilityConfig.Limits.MinimumFallingDelay then
              table.insert(
                errors,
                string.format("stage %s falling platform delay below Adventure floor", stageLabel(stage))
              )
            end
          end
        end
      end
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
  local ownedKeyCount = 0
  for _, key in ipairs(CollectionService:GetTagged("KeyCollectible")) do
    local owned = false
    local owningStageIndex = nil
    for _, stage in ipairs(stages) do
      if stage.model and typeof(stage.model) == "Instance" and key:IsDescendantOf(stage.model) then
        owned = true
        owningStageIndex = stage.stageIndex
        break
      end
    end
    if owned then
      ownedKeyCount += 1
      local keyId = key:GetAttribute("KeyId")
      if type(keyId) ~= "string" or #keyId == 0 or #keyId > 80 then
        table.insert(errors, "collectible missing KeyId: " .. key:GetFullName())
      elseif ids[keyId] then
        table.insert(errors, "duplicate collectible id: " .. keyId)
      else
        ids[keyId] = true
      end
      local declaredStage = key:GetAttribute("StageIndex")
      if declaredStage ~= owningStageIndex then
        table.insert(errors, string.format("collectible %s has incorrect stage ownership", tostring(keyId)))
      end
    end
  end
  local expectedKeys = totalStages * math.max(0, GameConfig.AuthoredKeysPerChapter or 0)
  if ownedKeyCount ~= expectedKeys then
    table.insert(errors, string.format("expected %d owned collectibles, found %d", expectedKeys, ownedKeyCount))
  end
  for _, stage in ipairs(stages) do
    if typeof(stage.model) == "Instance" and stage.model:IsA("Model") then
      for _, descendant in ipairs(stage.model:GetDescendants()) do
        if descendant:IsA("BasePart") and not descendant.Anchored then
          local intentionalRide = descendant:FindFirstAncestorWhichIsA("Model")
          local isCartPart = intentionalRide and intentionalRide:FindFirstChild("Seat") ~= nil
          local isIntentionalPhysics = descendant:GetAttribute("PhysicsDecor") == true
          if not isCartPart and not isIntentionalPhysics then
            table.insert(errors, "unanchored environment part: " .. descendant:GetFullName())
          end
        end
      end
    end
  end
  return errors, #stages
end

return WorldValidator
