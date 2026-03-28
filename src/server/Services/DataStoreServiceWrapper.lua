local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Wrapper = {}
Wrapper.__index = Wrapper

function Wrapper.new(name)
  local self = setmetatable({}, Wrapper)
  self.enabled = GameConfig.UseDataStore and not RunService:IsStudio()
  self.store = self.enabled and DataStoreService:GetDataStore(name or GameConfig.DataStoreName) or nil
  return self
end

function Wrapper:GetAsync(key)
  if not self.enabled then
    return nil
  end
  local ok, result = pcall(function()
    return self.store:GetAsync(key)
  end)
  if ok then
    return result
  else
    warn("DataStore get failed", result)
  end
  return nil
end

function Wrapper:SetAsync(key, value)
  if not self.enabled then
    return
  end
  local ok, err = pcall(function()
    self.store:SetAsync(key, value)
  end)
  if not ok then
    warn("DataStore set failed", err)
  end
end

return Wrapper
