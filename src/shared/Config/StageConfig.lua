--!strict
local Definitions = require(script.Parent.StageDefinitions)
local RoutePlan = require(script.Parent.Parent.Util.RoutePlan)
local StageConfig = { Definitions = {} }
for index, authored in ipairs(Definitions) do
  local route = {}
  for nodeIndex, node in ipairs(RoutePlan.stage(authored)) do
    table.insert(route, {
      id = "main_" .. nodeIndex,
      localPosition = Vector3.new(node.x, node.y, node.z),
      minLandingSize = Vector2.new(node.width, node.depth),
    })
  end
  StageConfig.Definitions[index] = {
    id = authored.id,
    index = index,
    name = authored.displayName,
    zone = authored.zone,
    difficulty = (index - 1) / 17,
    requiredRoute = route,
  }
end
function StageConfig.getByIndex(index)
  return StageConfig.Definitions[index]
end
return StageConfig
