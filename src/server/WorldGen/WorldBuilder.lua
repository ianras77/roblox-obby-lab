local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local RandomUtil = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Random"))
local ZoneBuilder = require(script.Parent.ZoneBuilder)
local DecorBuilder = require(script.Parent.DecorBuilder)

local WorldBuilder = {}

local function clearExisting()
  local existing = workspace:FindFirstChild("Obby")
  if existing then
    existing:Destroy()
  end
  local weather = workspace:FindFirstChild("Weather")
  if weather then
    weather:Destroy()
  end
end

local function ensureFolders()
  local folder = ReplicatedStorage:FindFirstChild("SharedEvents")
  if not folder then
    folder = Instance.new("Folder")
    folder.Name = "SharedEvents"
    folder.Parent = ReplicatedStorage
  end
  local events = { GameConfig.ProgressRemote, GameConfig.KeyRemote, GameConfig.FinaleRemote }
  for _, name in ipairs(events) do
    if not folder:FindFirstChild(name) then
      local evt = Instance.new("RemoteEvent")
      evt.Name = name
      evt.Parent = folder
    end
  end
  return folder:FindFirstChild(GameConfig.ProgressRemote),
    folder:FindFirstChild(GameConfig.KeyRemote),
    folder:FindFirstChild(GameConfig.FinaleRemote)
end

function WorldBuilder.buildWorld(seed)
  seed = seed or GameConfig.Seed
  clearExisting()
  local progressEvent, keyEvent, finaleEvent = ensureFolders()

  local obbyModel = Instance.new("Model")
  obbyModel.Name = "Obby"
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

  local rng = RandomUtil.new(seed)
  local totalStages = GameConfig.Zones * GameConfig.StagesPerZone
  local lastCFrame = CFrame.new(0, 5, 0)
  local allStages = {}

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
    })
    DecorBuilder.decorateZone(zoneModel, zoneCfg)
    DecorBuilder.applyLighting(zoneCfg)
    for _, s in ipairs(stages) do
      table.insert(allStages, s)
    end
    lastCFrame = endCFrame * CFrame.new(GameConfig.StageSpacing.X, GameConfig.ElevationPerZone, 0)
  end

  print(string.format("[Obby] Built %d zones, %d stages, seed=%s", GameConfig.Zones, totalStages, tostring(seed)))
  progressEvent:FireAllClients({ total = totalStages, stage = 0 })

  return {
    model = obbyModel,
    stages = allStages,
    seed = seed,
    totalStages = totalStages,
    progressEvent = progressEvent,
    keyEvent = keyEvent,
    finaleEvent = finaleEvent,
  }
end

return WorldBuilder
