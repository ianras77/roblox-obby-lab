--!strict
-- Numeric route geometry is shared by generation and non-Studio tests.
local RoutePlan = {}
function RoutePlan.stage(definition)
  local nodes = {}
  local gentle = definition.index == 10 or definition.index == 14 or definition.index == 18
  for i = 0, 6 do
    table.insert(nodes, { x = i * 16, y = 0, z = 0, width = gentle and 16 or 14, depth = 14, stable = true })
  end
  return nodes
end
function RoutePlan.validate(nodes, gapBudget, stepBudget)
  local errors = {}
  for i, node in ipairs(nodes) do
    if not node.stable or node.width < 10 or node.depth < 10 then
      table.insert(errors, "unstable or narrow landing " .. i)
    end
    if i > 1 then
      local previous = nodes[i - 1]
      local gap = node.x - previous.x - (node.width + previous.width) / 2
      if gap > gapBudget or math.abs(node.y - previous.y) > stepBudget then
        table.insert(errors, "gap or step budget exceeded at " .. i)
      end
    end
  end
  return errors
end
function RoutePlan.connector(a, b)
  local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
  return {
    length = math.sqrt(dx * dx + dy * dy + dz * dz),
    slope = math.abs(dy) / math.max(1, math.sqrt(dx * dx + dz * dz)),
  }
end
return RoutePlan
