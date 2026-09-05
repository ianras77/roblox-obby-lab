local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))
local RandomUtil = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Random"))
local ZoneBuilder = require(script.Parent.ZoneBuilder)
local DecorBuilder = require(script.Parent.DecorBuilder)
local WorldValidator = require(script.Parent.WorldValidator)
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))

local RouteBuilder = require(script.Parent.RouteBuilder)
local RouteValidator = require(script.Parent.RouteValidator)
local WorldBuilder = {}

local function ensureRemote(folder, name, className)
  local existing = folder:FindFirstChild(name)
  if existing then
    if not existing:IsA(className) then
      error(string.format("SharedEvents.%s must be a %s", name, className))
    end
    return existing
  end
  local remote = Instance.new(className)
  remote.Name = name
  remote.Parent = folder
  return remote
end

local function clearExisting()
  local existing = workspace:FindFirstChild("GeneratedObby")
  if existing then
    if existing:GetAttribute("GeneratorOwner") ~= "ToadsGreatEscape" then
      error("Refusing to delete Workspace.GeneratedObby without generator ownership")
    end
    existing:Destroy()
  end
end

local function ensureFolders()
  local folder = ReplicatedStorage:FindFirstChild("SharedEvents")
  if not folder then
    folder = Instance.new("Folder")
    folder.Name = "SharedEvents"
    folder.Parent = ReplicatedStorage
  end
  local events = {
    "Assistance",
    RemoteContracts.Progress.name,
    RemoteContracts.Keys.name,
    RemoteContracts.Finale.name,
    RemoteContracts.SetSettings.name,
    RemoteContracts.SetMode.name,
    RemoteContracts.PracticeStage.name,
  }
  for _, name in ipairs(events) do
    ensureRemote(folder, name, "RemoteEvent")
  end
  local stateFunction = ensureRemote(folder, RemoteContracts.State.name, "RemoteFunction")
  return folder:FindFirstChild(RemoteContracts.Progress.name),
    folder:FindFirstChild(RemoteContracts.Keys.name),
    folder:FindFirstChild(RemoteContracts.Finale.name),
    stateFunction
end

function WorldBuilder.buildWorld(seed)
  seed = seed or GameConfig.Seed
  if type(seed) ~= "number" or seed ~= seed or seed % 1 ~= 0 or seed < 0 or seed > GameConfig.MaxDevSeed then
    error(string.format("Invalid world seed: %s", tostring(seed)))
  end
  clearExisting()
  local progressEvent, keyEvent, finaleEvent, stateFunction = ensureFolders()

  local obbyModel = Instance.new("Model")
  obbyModel.Name = "GeneratedObby"
  obbyModel:SetAttribute("GeneratorOwner", "ToadsGreatEscape")
  obbyModel:SetAttribute("GeneratorVersion", WorldGenConfig.GeneratorVersion)
  obbyModel:SetAttribute("Seed", seed)
  obbyModel.Parent = workspace

  -- Spawn pad for clean starting flow
  local spawnPad = Instance.new("SpawnLocation")
  spawnPad.Name = "SpawnPad"
  spawnPad.Size = Vector3.new(16, 1, 16)
  spawnPad.Position = Vector3.new(0, 4.5, -20)
  spawnPad.Anchored = true
  spawnPad.Transparency = 0.2
  spawnPad.BrickColor = BrickColor.new("Bright green")
  spawnPad.Duration = 0
  spawnPad.Parent = obbyModel

  local startGate = Instance.new("Part")
  startGate.Name = "TimeTrialStartGate"
  startGate.Size = Vector3.new(20, 8, 2)
  startGate.CFrame = CFrame.new(0, 8, -8)
  startGate.Anchored = true
  startGate.CanCollide = false
  startGate.Transparency = 0.35
  startGate.Color = Color3.fromRGB(255, 220, 120)
  CollectionService:AddTag(startGate, "RunStartGate")
  startGate.Parent = obbyModel

  RouteBuilder.connect(obbyModel, spawnPad.CFrame, CFrame.new(0, 5, 0), "SpawnBridge")
  local rng = RandomUtil.new(seed)
  local totalStages = GameConfig.Zones * GameConfig.StagesPerZone
  local lastCFrame = CFrame.new(0, 5, 0)
  local previousZoneExit = nil
  local allStages = {}
  local zones = {}

  for zoneIndex = 1, GameConfig.Zones do
    local zoneCfg = ZoneConfig[((zoneIndex - 1) % #ZoneConfig) + 1]
    local zoneModel, stages, endCFrame = ZoneBuilder.buildZone({
      parent = obbyModel,
      origin = lastCFrame,
      zoneIndex = zoneIndex,
      stagesPerZone = GameConfig.StagesPerZone,
      zoneConfig = zoneCfg,
      random = rng,
      elevationStep = GameConfig.ElevationPerZone / GameConfig.StagesPerZone,
      previousExit = previousZoneExit,
    })
    DecorBuilder.decorateZone(zoneModel, zoneCfg)
    local zoneCFrame, zoneSize = zoneModel:GetBoundingBox()
    table.insert(zones, {
      model = zoneModel,
      zoneIndex = zoneIndex,
      entrance = lastCFrame,
      exit = endCFrame,
      bounds = zoneSize,
      center = zoneCFrame.Position,
    })
    -- Lighting presentation is transitioned locally by EnvironmentController.
    for _, s in ipairs(stages) do
      table.insert(allStages, s)
    end
    previousZoneExit = endCFrame
    lastCFrame = endCFrame * CFrame.new(GameConfig.StageSpacing.X, GameConfig.ElevationPerZone, 0)
  end

  RouteBuilder.connect(
    obbyModel,
    allStages[#allStages].exit,
    allStages[#allStages].exit * CFrame.new(24, 0, 0),
    "FinaleReplayDeck"
  )
  RouteValidator.assertWorld(allStages, obbyModel, spawnPad)
  local validationErrors = WorldValidator.validate(allStages, totalStages, zones, obbyModel)
  for _, err in ipairs(validationErrors) do
    warn("[WorldValidator] " .. err)
  end
  if #validationErrors > 0 then
    obbyModel:Destroy()
    error(string.format("Generated obby failed validation with %d error(s)", #validationErrors))
  end

  print(string.format("[Obby] Built %d zones, %d stages, seed=%s", GameConfig.Zones, totalStages, tostring(seed)))
  return {
    model = obbyModel,
    startGate = startGate,
    stages = allStages,
    zones = zones,
    seed = seed,
    totalStages = totalStages,
    progressEvent = progressEvent,
    keyEvent = keyEvent,
    finaleEvent = finaleEvent,
    stateFunction = stateFunction,
    validationErrors = validationErrors,
  }
end

return WorldBuilder
