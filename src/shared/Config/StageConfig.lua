--!strict

local WorldGenConfig = require(script.Parent.WorldGenConfig)
local GameConfig = require(script.Parent.GameConfig)

export type StageDefinition = {
  id: string,
  index: number,
  name: string,
  zone: number,
  difficulty: number,
  requiredRoute: { { id: string, localPosition: Vector3, minLandingSize: Vector2 } },
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
    -- Stable, authored route anchors. Templates may add intermediate anchors,
    -- but the entrance-to-exit spine is never inferred from optional props.
    requiredRoute = {
      { id = "entrance", localPosition = Vector3.new(0, 0, 0), minLandingSize = Vector2.new(10, 10) },
      { id = "checkpoint-approach", localPosition = Vector3.new(24, 0, 0), minLandingSize = Vector2.new(8, 8) },
      { id = "exit", localPosition = Vector3.new(52, 0, 0), minLandingSize = Vector2.new(8, 8) },
    },
  }
end

function StageConfig.getByIndex(index: number): StageDefinition?
  return StageConfig.Definitions[index]
end

return StageConfig
