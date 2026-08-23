local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))

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
  self.enabled = GameConfig.UseDataStore
    and GameConfig.SaveCheckpoints
    and GameConfig.Environment ~= "StudioDevelopment"
  if RunService:IsStudio() and GameConfig.Environment == "Production" then
    warn("[DataStore] Production environment is blocked in Studio")
    self.enabled = false
  end
  local storeName = name or GameConfig.DataStoreName
  if RunService:IsStudio() and GameConfig.Environment == "StudioSandbox" then
    storeName = storeName .. "_StudioSandbox"
  end
  self.store = self.enabled and DataStoreService:GetDataStore(storeName) or nil
  self.maxAttempts = 3
  return self
end

function Wrapper:GetAsync(key)
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
  if not self.enabled then
    return
  end
  for attempt = 1, self.maxAttempts do
    if not hasBudget(Enum.DataStoreRequestType.UpdateAsync) then
      warn("[DataStore] UpdateAsync budget exhausted; preserving unsaved session state")
      return false
    end
    local ok, err = pcall(function()
      self.store:UpdateAsync(key, function(current)
        if type(current) ~= "table" then
          return value
        end
        local merged = table.clone(value)
        merged.highestChapter = math.max(tonumber(current.highestChapter) or 0, value.highestChapter or 0)
        merged.totalDeaths = math.max(tonumber(current.totalDeaths) or 0, value.totalDeaths or 0)
        merged.completionCount = math.max(tonumber(current.completionCount) or 0, value.completionCount or 0)
        if type(current.collectedKeys) == "table" then
          merged.collectedKeys = table.clone(value.collectedKeys or {})
          local keyCount = 0
          for keyId, collected in pairs(current.collectedKeys) do
            if collected == true and keyCount < 100 then
              merged.collectedKeys[keyId] = true
              keyCount += 1
            end
          end
        end
        local currentBest = tonumber(current.bestRunMs)
        if currentBest and currentBest > 0 and (not merged.bestRunMs or currentBest < merged.bestRunMs) then
          merged.bestRunMs = currentBest
        end
        if type(current.bestChapterMs) == "table" then
          merged.bestChapterMs = table.clone(value.bestChapterMs or {})
          for chapter, timeMs in pairs(current.bestChapterMs) do
            local oldTime = tonumber(timeMs)
            local newTime = tonumber(merged.bestChapterMs[chapter])
            if oldTime and oldTime > 0 and (not newTime or oldTime < newTime) then
              merged.bestChapterMs[chapter] = math.floor(oldTime)
            end
          end
        end
        if type(current.settings) == "table" then
          merged.settings = table.clone(value.settings or {})
          for setting, enabled in pairs(current.settings) do
            if type(enabled) == "boolean" and type(merged.settings[setting]) == "boolean" then
              merged.settings[setting] = enabled
            end
          end
        end
        return merged
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
