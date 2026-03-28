local RandomUtil = {}
RandomUtil.__index = RandomUtil

function RandomUtil.new(seed)
  local self = setmetatable({}, RandomUtil)
  self.random = Random.new(seed or tick())
  return self
end

function RandomUtil:NextNumber(min, max)
  return self.random:NextNumber(min or 0, max or 1)
end

function RandomUtil:NextInteger(min, max)
  return self.random:NextInteger(min or 1, max or 1)
end

function RandomUtil:Choice(list)
  return list[self:NextInteger(1, #list)]
end

function RandomUtil:Shuffle(list)
  for i = #list, 2, -1 do
    local j = self:NextInteger(1, i)
    list[i], list[j] = list[j], list[i]
  end
  return list
end

return RandomUtil
