--!strict

export type PlayerProfile = {
  schemaVersion: number,
  highestChapter: number,
  collectedKeys: { [string]: boolean },
  bestRunMs: number?,
  bestChapterMs: { [string]: number },
  totalDeaths: number,
  completionCount: number,
  settings: { [string]: any },
}

local ProfileSchema = {}
ProfileSchema.CurrentVersion = 1
ProfileSchema.MaxCollectedKeys = 100
ProfileSchema.MaxChapter = 18
ProfileSchema.MaxCounter = 1000000000

function ProfileSchema.default(): PlayerProfile
  return {
    schemaVersion = ProfileSchema.CurrentVersion,
    highestChapter = 0,
    collectedKeys = {},
    bestRunMs = nil,
    bestChapterMs = {},
    totalDeaths = 0,
    completionCount = 0,
    settings = {
      reducedMotion = false,
      reduceFlashes = false,
      highContrast = false,
      largeText = false,
      lowParticles = false,
      showTimer = true,
      uiScale = 1,
    },
  }
end

function ProfileSchema.sanitize(raw: any): PlayerProfile
  local profile = ProfileSchema.default()
  if type(raw) ~= "table" then
    return profile
  end
  profile.schemaVersion = ProfileSchema.CurrentVersion
  -- Migrate the original checkpoint-only record without trusting its shape.
  local legacyChapter = raw.checkpoint
  profile.highestChapter =
    math.clamp(math.max(0, math.floor(tonumber(raw.highestChapter or legacyChapter) or 0)), 0, ProfileSchema.MaxChapter)
  profile.totalDeaths = math.clamp(math.max(0, math.floor(tonumber(raw.totalDeaths) or 0)), 0, ProfileSchema.MaxCounter)
  profile.completionCount =
    math.clamp(math.max(0, math.floor(tonumber(raw.completionCount) or 0)), 0, ProfileSchema.MaxCounter)
  local bestRunMs = tonumber(raw.bestRunMs)
  if bestRunMs and bestRunMs > 0 and bestRunMs < 86400000 then
    profile.bestRunMs = math.floor(bestRunMs)
  end
  if type(raw.bestChapterMs) == "table" then
    for chapter, timeMs in pairs(raw.bestChapterMs) do
      local chapterNumber = tonumber(chapter)
      local validTime = tonumber(timeMs)
      if
        chapterNumber
        and validTime
        and chapterNumber % 1 == 0
        and chapterNumber >= 1
        and chapterNumber <= ProfileSchema.MaxChapter
        and validTime > 0
        and validTime < 86400000
      then
        profile.bestChapterMs[tostring(chapterNumber)] = math.floor(validTime)
      end
    end
  end
  if type(raw.collectedKeys) == "table" then
    local keyCount = 0
    for key, value in pairs(raw.collectedKeys) do
      if type(key) == "string" and value == true and #key <= 80 then
        profile.collectedKeys[key] = true
        keyCount += 1
        if keyCount >= ProfileSchema.MaxCollectedKeys then
          break
        end
      end
    end
  end
  if type(raw.settings) == "table" then
    for key, defaultValue in pairs(profile.settings) do
      if type(defaultValue) == "boolean" and type(raw.settings[key]) == "boolean" then
        profile.settings[key] = raw.settings[key]
      end
    end
    local uiScale = tonumber(raw.settings.uiScale)
    if uiScale and uiScale >= 0.8 and uiScale <= 1.5 then
      profile.settings.uiScale = uiScale
    end
  end
  return profile
end

return ProfileSchema
