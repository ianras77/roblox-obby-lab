local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Wrapper = {}
Wrapper.__index = Wrapper

function Wrapper.new(name)
  local self = setmetatable({}, Wrapper)
  self.enabled = GameConfig.UseDataStore and GameConfig.Environment ~= "StudioDevelopment"
  if RunService:IsStudio() and GameConfig.Environment == "Production" then
    warn("[DataStore] Production environment is blocked in Studio")
    self.enabled = false
  end
  self.store = self.enabled and DataStoreService:GetDataStore(name or GameConfig.DataStoreName) or nil
  self.maxAttempts = 3
  return self
end

function Wrapper:GetAsync(key)
  if not self.enabled then
    return nil
  end
  for attempt = 1, self.maxAttempts do
    local ok, result = pcall(function()
      return self.store:GetAsync(key)
    end)
    if ok then
      return result
    end
    warn(string.format("DataStore get failed (attempt %d): %s", attempt, tostring(result)))
    task.wait(2 ^ (attempt - 1))
  end
  return nil
end

function Wrapper:SetAsync(key, value)
  if not self.enabled then
    return
  end
  for attempt = 1, self.maxAttempts do
    local ok, err = pcall(function()
      self.store:UpdateAsync(key, function()
        return value
      end)
    end)
    if ok then
      return true
    end
    warn(string.format("DataStore set failed (attempt %d): %s", attempt, tostring(err)))
    task.wait(2 ^ (attempt - 1))
  end
  return false
end

return Wrapper
