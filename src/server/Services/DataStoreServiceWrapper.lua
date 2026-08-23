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
        local mergedKeys = {}
        local keyCount = 0
        local function mergeKeys(source)
          if type(source) ~= "table" then
            return
          end
          for keyId, collected in pairs(source) do
            if keyCount >= 100 then
              return
            end
            if type(keyId) == "string" and #keyId <= 100 and collected == true and not mergedKeys[keyId] then
              mergedKeys[keyId] = true
              keyCount += 1
            end
          end
        end
        mergeKeys(value.collectedKeys)
        mergeKeys(current.collectedKeys)
        merged.collectedKeys = mergedKeys
        local currentBest = tonumber(current.bestRunMs)
        if currentBest and currentBest > 0 and (not merged.bestRunMs or currentBest < merged.bestRunMs) then
          merged.bestRunMs = currentBest
        end
        if type(current.bestChapterMs) == "table" then
          merged.bestChapterMs = table.clone(value.bestChapterMs or {})
          for chapter, timeMs in pairs(current.bestChapterMs) do
            local chapterNumber = tonumber(chapter)
            local oldTime = tonumber(timeMs)
            local newTime = tonumber(merged.bestChapterMs[chapter])
            if
              chapterNumber
              and chapterNumber % 1 == 0
              and chapterNumber >= 1
              and chapterNumber <= 18
              and oldTime
              and oldTime > 0
              and oldTime < 86400000
              and (not newTime or newTime < 1 or oldTime < newTime)
            then
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
