--!strict

local WorldGenConfig = require(script.Parent.WorldGenConfig)
local GameConfig = require(script.Parent.GameConfig)

export type StageDefinition = {
  id: string,
  index: number,
  name: string,
  zone: number,
  difficulty: number,
}

local StageConfig = {}
StageConfig.Definitions = {}

for index, stageType in ipairs(WorldGenConfig.StageTypes) do
  StageConfig.Definitions[index] = {
    id = string.lower(stageType:gsub("(%u)", "_%1"):gsub("^_", "")),
    index = index,
    name = WorldGenConfig.StageDisplayNames[stageType] or stageType,
    zone = math.ceil(index / GameConfig.StagesPerZone),
    difficulty = math.clamp((index - 1) / 17, 0, 1),
  }
end

function StageConfig.getByIndex(index: number): StageDefinition?
  return StageConfig.Definitions[index]
end

return StageConfig
