--!strict
local MovementMath = {}
function MovementMath.omega(period)
  assert(period > 0, "PeriodSeconds must be positive")
  return 2 * math.pi / period
end
-- Scalar form avoids a Roblox dependency in tests. Preserve vertical and transverse steering.
function MovementMath.influence(x, y, z, dx, dz, speed, dt)
  local magnitude = math.sqrt(dx * dx + dz * dz)
  if magnitude < 0.001 then
    return x, y, z
  end
  dx, dz = dx / magnitude, dz / magnitude
  local along = x * dx + z * dz
  local addition = math.clamp(speed - along, 0, 12 * math.clamp(dt, 0, 0.25))
  return x + dx * addition, y, z + dz * addition
end
function MovementMath.phase(time, cycle, warning)
  local t = time % cycle
  if t < cycle * 0.4 then
    return "inactive"
  end
  if t < cycle * 0.4 + warning then
    return "warning"
  end
  if t < cycle * 0.85 then
    return "active"
  end
  return "recovery"
end
function MovementMath.hazardActive(state, canTouch)
  return canTouch == true and (state == nil or state == "active")
end
return MovementMath
