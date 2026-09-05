local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageBuilder = require(script.Parent.StageBuilder)
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local RouteBuilder = require(script.Parent.RouteBuilder)
local ZoneBuilder = {}

function ZoneBuilder.buildZone(args)
  local zoneModel = Instance.new("Model")
  zoneModel.Name = string.format("Zone_%02d_%s", args.zoneIndex, args.zoneConfig.Name)
  zoneModel.Parent = args.parent

  local stages = {}
  local currentCFrame = args.origin
  local previousExit = args.previousExit
  for i = 1, args.stagesPerZone do
    local stageIndex = ((args.zoneIndex - 1) * args.stagesPerZone) + i
    local stageType = WorldGenConfig.StageTypes[((stageIndex - 1) % #WorldGenConfig.StageTypes) + 1]
    local result = StageBuilder.buildStage({
      parent = zoneModel,
      origin = currentCFrame,
      stageIndex = stageIndex,
      stageType = stageType,
      zoneColor = args.zoneConfig.ThemeColor,
      random = args.random,
    })
    if previousExit then
      RouteBuilder.connect(zoneModel, previousExit, result.entrance)
    end
    local connectorLength = previousExit and (result.entrance.Position - previousExit.Position).Magnitude or 0
    result.model:SetAttribute("ZoneIndex", args.zoneIndex)
    table.insert(stages, {
      model = result.model,
      mainPathNodes = result.mainPathNodes,
      challengePathNodes = result.challengePathNodes,
      finish = result.finish,
      primaryMechanic = result.primaryMechanic,
      expectedNoviceSeconds = result.expectedNoviceSeconds,
      difficultyTier = result.difficultyTier,
      checkpoint = result.checkpoint,
      stageIndex = stageIndex,
      stageType = stageType,
      stageId = result.model:GetAttribute("StageId"),
      entrance = result.entrance,
      exit = result.exit,
      safeSpawn = result.safeSpawn,
      bounds = result.bounds,
      mechanics = result.mechanics,
      pathCorridor = result.pathCorridor,
      connectorLength = connectorLength,
      zoneIndex = args.zoneIndex,
      zoneModel = zoneModel,
    })
    previousExit = result.exit
    currentCFrame = result.exit * CFrame.new(GameConfig.StageSpacing.X, 0, 0)
  end

  -- Return the actual final stage exit. The world builder owns the connector
  -- between zones and applies the configured elevation exactly once.
  return zoneModel, stages, previousExit
end

return ZoneBuilder
