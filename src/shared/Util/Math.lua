local Math = {}

function Math.lerp(a, b, t)
  return a + (b - a) * t
end

function Math.clamp(x, min, max)
  if x < min then
    return min
  end
  if x > max then
    return max
  end
  return x
end

return Math
