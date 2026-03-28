local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageBuilder = require(script.Parent.StageBuilder)
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local ZoneBuilder = {}

function ZoneBuilder.buildZone(args)
  local zoneModel = Instance.new("Model")
  zoneModel.Name = string.format("Zone_%02d_%s", args.zoneIndex, args.zoneConfig.Name)
  zoneModel.Parent = args.parent

  local stages = {}
  local currentCFrame = args.origin
  for i = 1, args.stagesPerZone do
    local stageIndex = ((args.zoneIndex - 1) * args.stagesPerZone) + i
    local stageType = WorldGenConfig.StageTypes[((stageIndex - 1) % #WorldGenConfig.StageTypes) + 1]
    local stageModel, endCFrame, checkpoint = StageBuilder.buildStage({
      parent = zoneModel,
      origin = currentCFrame,
      stageIndex = stageIndex,
      stageType = stageType,
      zoneColor = args.zoneConfig.ThemeColor,
      random = args.random,
    })
    table.insert(stages, {
      model = stageModel,
      checkpoint = checkpoint,
      stageIndex = stageIndex,
      stageType = stageType,
    })
    currentCFrame = endCFrame * CFrame.new(GameConfig.StageSpacing.X, args.elevationStep, 0)
  end

  return zoneModel, stages, currentCFrame
end

return ZoneBuilder
