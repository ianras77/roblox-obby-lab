--!strict

export type PlayerProfile = {
  schemaVersion: number,
  medals: { [string]: boolean },
  assistedChapters: { [string]: boolean },
  highestChapter: number,
  collectedKeys: { [string]: boolean },
  bestRunMs: number?,
  bestChapterMs: { [string]: number },
  totalDeaths: number,
  completionCount: number,
  settings: { [string]: any },
}

local ProfileSchema = {}
ProfileSchema.CurrentVersion = 2
ProfileSchema.MaxCollectedKeys = 100
ProfileSchema.MaxChapter = 18
ProfileSchema.MaxCounter = 1000000000

local function finiteNumber(value: any): number?
  local number = tonumber(value)
  if not number or number ~= number or math.abs(number) == math.huge then
    return nil
  end
  return number
end

function ProfileSchema.default(): PlayerProfile
  return {
    schemaVersion = ProfileSchema.CurrentVersion,
    medals = {},
    assistedChapters = {},
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
      masterVolume = 1,
      musicVolume = 1,
      sfxVolume = 1,
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
  profile.highestChapter = math.clamp(
    math.max(0, math.floor(finiteNumber(raw.highestChapter or legacyChapter) or 0)),
    0,
    ProfileSchema.MaxChapter
  )
  profile.totalDeaths =
    math.clamp(math.max(0, math.floor(finiteNumber(raw.totalDeaths) or 0)), 0, ProfileSchema.MaxCounter)
  profile.completionCount =
    math.clamp(math.max(0, math.floor(finiteNumber(raw.completionCount) or 0)), 0, ProfileSchema.MaxCounter)
  local bestRunMs = finiteNumber(raw.bestRunMs)
  if bestRunMs and bestRunMs > 0 and bestRunMs < 86400000 then
    profile.bestRunMs = math.floor(bestRunMs)
  end
  if type(raw.bestChapterMs) == "table" then
    for chapter, timeMs in pairs(raw.bestChapterMs) do
      local chapterNumber = finiteNumber(chapter)
      local validTime = finiteNumber(timeMs)
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
  for index = 1, ProfileSchema.MaxChapter do
    local key = tostring(index)
    if type(raw.assistedChapters) == "table" and raw.assistedChapters[key] == true then
      profile.assistedChapters[key] = true
    end
    for _, kind in ipairs({ "Story", "Explorer", "Toad" }) do
      local medal = kind .. key
      if type(raw.medals) == "table" and raw.medals[medal] == true then
        profile.medals[medal] = true
      end
    end
    if index <= profile.highestChapter then
      profile.medals["Story" .. key] = true
    end
  end
  if type(raw.settings) == "table" then
    for key, defaultValue in pairs(profile.settings) do
      if type(defaultValue) == "boolean" and type(raw.settings[key]) == "boolean" then
        profile.settings[key] = raw.settings[key]
      end
    end
    local uiScale = finiteNumber(raw.settings.uiScale)
    if uiScale and uiScale >= 0.8 and uiScale <= 1.5 then
      profile.settings.uiScale = uiScale
    end
    for _, key in ipairs({ "masterVolume", "musicVolume", "sfxVolume" }) do
      local volume = finiteNumber(raw.settings[key])
      if volume and volume >= 0 and volume <= 1 then
        profile.settings[key] = volume
      end
    end
  end
  return profile
end

-- Concurrent servers may advance, never erase earned progress or faster times.
function ProfileSchema.merge(current, incoming): PlayerProfile
  local old = ProfileSchema.sanitize(current)
  local result = ProfileSchema.sanitize(incoming)
  result.highestChapter = math.max(old.highestChapter, result.highestChapter)
  result.completionCount = math.max(old.completionCount, result.completionCount)
  result.totalDeaths = math.max(old.totalDeaths, result.totalDeaths)
  for _, field in ipairs({ "collectedKeys", "medals", "assistedChapters" }) do
    for key, earned in pairs(old[field]) do
      if earned then
        result[field][key] = true
      end
    end
  end
  if old.bestRunMs and (not result.bestRunMs or old.bestRunMs < result.bestRunMs) then
    result.bestRunMs = old.bestRunMs
  end
  for key, value in pairs(old.bestChapterMs) do
    if not result.bestChapterMs[key] or value < result.bestChapterMs[key] then
      result.bestChapterMs[key] = value
    end
  end
  return ProfileSchema.sanitize(result)
end

return ProfileSchema
