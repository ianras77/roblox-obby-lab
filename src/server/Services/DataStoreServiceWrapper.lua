local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))
local ProfileSchema = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("ProfileSchema"))

local mockStores = {}
local Wrapper = {}
Wrapper.__index = Wrapper

local function hasBudget(requestType)
  local ok, budget = pcall(function()
    return DataStoreService:GetRequestBudgetForRequestType(requestType)
  end)
  return ok and budget >= 1
end

function Wrapper.new(name)
  local self = setmetatable({}, Wrapper)
  local isStudioSandbox = RunService:IsStudio() and GameConfig.Environment == "StudioSandbox"
  local environmentAllowsPersistence = GameConfig.Environment == "Staging"
    or GameConfig.Environment == "Production"
    or isStudioSandbox
  self.enabled = GameConfig.UseDataStore and GameConfig.SaveCheckpoints and environmentAllowsPersistence
  if not environmentAllowsPersistence then
    warn(string.format("[DataStore] Persistence disabled for environment %s", tostring(GameConfig.Environment)))
  end
  if RunService:IsStudio() and GameConfig.Environment == "Production" then
    warn("[DataStore] Production environment is blocked in Studio")
    self.enabled = false
  end
  local storeName = name or GameConfig.DataStoreName
  if RunService:IsStudio() and GameConfig.Environment == "StudioSandbox" then
    storeName = storeName .. "_StudioSandbox"
  end
  storeName = storeName .. "_" .. GameConfig.Environment
  self.mock = RunService:IsStudio() and GameConfig.Environment ~= "StudioSandbox"
  if self.mock then
    self.enabled = false
  end
  mockStores[storeName] = mockStores[storeName] or {}
  self.mockStore = mockStores[storeName]
  self.store = self.enabled and DataStoreService:GetDataStore(storeName) or nil
  self.maxAttempts = 3
  return self
end

function Wrapper:isEnabled(): boolean
  return self.enabled
end

function Wrapper:GetAsync(key)
  if self.mock then
    return self.mockStore[key], true
  end
  if not self.enabled then
    return nil, true
  end
  for attempt = 1, self.maxAttempts do
    if not hasBudget(Enum.DataStoreRequestType.GetAsync) then
      warn("[DataStore] GetAsync budget exhausted; keeping session defaults")
      return nil, false
    end
    local ok, result = pcall(function()
      return self.store:GetAsync(key)
    end)
    if ok then
      return result, true
    end
    warn(string.format("DataStore get failed (attempt %d): %s", attempt, tostring(result)))
    task.wait(2 ^ (attempt - 1))
  end
  return nil, false
end

function Wrapper:SetAsync(key, value)
  if self.mock then
    self.mockStore[key] = ProfileSchema.merge(self.mockStore[key], value)
    return true
  end
  if not self.enabled then
    return
  end
  -- Keep the persistence boundary defensive even if a future caller passes a
  -- mutable or malformed profile table.
  value = ProfileSchema.sanitize(value)
  for attempt = 1, self.maxAttempts do
    if not hasBudget(Enum.DataStoreRequestType.UpdateAsync) then
      warn("[DataStore] UpdateAsync budget exhausted; preserving unsaved session state")
      return false
    end
    local ok, err = pcall(function()
      self.store:UpdateAsync(key, function(current)
        return ProfileSchema.merge(current, value)
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
