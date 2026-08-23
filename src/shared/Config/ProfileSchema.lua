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

function ProfileSchema.default(): PlayerProfile
  return {
    schemaVersion = ProfileSchema.CurrentVersion,
    highestChapter = 0,
    collectedKeys = {},
    bestRunMs = nil,
    bestChapterMs = {},
    totalDeaths = 0,
    completionCount = 0,
    settings = { reducedMotion = false, highContrast = false, uiScale = 1 },
  }
end

function ProfileSchema.sanitize(raw: any): PlayerProfile
  local profile = ProfileSchema.default()
  if type(raw) ~= "table" then
    return profile
  end
  profile.schemaVersion = ProfileSchema.CurrentVersion
  profile.highestChapter = math.max(0, math.floor(tonumber(raw.highestChapter) or 0))
  profile.totalDeaths = math.max(0, math.floor(tonumber(raw.totalDeaths) or 0))
  profile.completionCount = math.max(0, math.floor(tonumber(raw.completionCount) or 0))
  if type(raw.collectedKeys) == "table" then
    for key, value in pairs(raw.collectedKeys) do
      if type(key) == "string" and value == true and #key <= 80 then
        profile.collectedKeys[key] = true
      end
    end
  end
  return profile
end

return ProfileSchema
