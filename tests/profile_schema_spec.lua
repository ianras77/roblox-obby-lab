--!strict
-- selene: allow(incorrect_standard_library_use)

local ProfileSchema = require("../src/shared/Config/ProfileSchema")

local function expect(condition: boolean, message: string)
  assert(condition, message)
end

local defaults = ProfileSchema.default()
expect(defaults.schemaVersion == ProfileSchema.CurrentVersion, "default version is current")
expect(defaults.highestChapter == 0, "default chapter is zero")
expect(defaults.bestRunMs == nil, "default has no personal best")
expect(defaults.settings.showTimer == true, "default timer is enabled")

local migrated = ProfileSchema.sanitize({
  checkpoint = 7,
  totalDeaths = -4,
  completionCount = 12.8,
  bestRunMs = 4321.9,
  bestChapterMs = { ["2"] = 2500.7, ["99"] = 1 },
  settings = { reducedMotion = true, uiScale = 1.25, masterVolume = 0.4 },
})
expect(migrated.highestChapter == 7, "legacy checkpoint migrates")
expect(migrated.totalDeaths == 0, "negative counters clamp")
expect(migrated.completionCount == 12, "counters floor")
expect(migrated.bestRunMs == 4321, "personal best floors")
expect(migrated.bestChapterMs["2"] == 2500, "valid split migrates")
expect(migrated.bestChapterMs["99"] == nil, "out-of-route split is rejected")
expect(migrated.settings.reducedMotion == true, "boolean setting migrates")
expect(migrated.settings.uiScale == 1.25, "scale setting migrates")
expect(migrated.settings.masterVolume == 0.4, "volume setting migrates")

local oversizedKeys = {}
for index = 1, ProfileSchema.MaxCollectedKeys + 10 do
  oversizedKeys[string.format("key_%03d", index)] = true
end
local bounded = ProfileSchema.sanitize({
  highestChapter = ProfileSchema.MaxChapter + 10,
  bestRunMs = 0,
  collectedKeys = oversizedKeys,
  settings = { uiScale = 4, musicVolume = -1 },
})
local keyCount = 0
for _ in pairs(bounded.collectedKeys) do
  keyCount += 1
end
expect(bounded.highestChapter == ProfileSchema.MaxChapter, "chapter is bounded")
expect(keyCount == ProfileSchema.MaxCollectedKeys, "keys are bounded")
expect(bounded.bestRunMs == nil, "zero personal best is rejected")
expect(bounded.settings.uiScale == 1, "invalid scale uses default")
expect(bounded.settings.musicVolume == 1, "invalid volume uses default")

local nonFinite = ProfileSchema.sanitize({ highestChapter = math.huge, bestRunMs = -math.huge })
expect(nonFinite.highestChapter == 0, "non-finite chapter uses default")
expect(nonFinite.bestRunMs == nil, "non-finite personal best is rejected")

local merged = ProfileSchema.merge({
  highestChapter = 15,
  completionCount = 3,
  collectedKeys = { older = true },
  medals = { Toad2 = true },
  assistedChapters = { ["3"] = true },
  bestRunMs = 10000,
  bestChapterMs = { ["2"] = 400 },
}, {
  highestChapter = 4,
  completionCount = 1,
  collectedKeys = { newer = true },
  medals = { Explorer4 = true },
  bestRunMs = 12000,
  bestChapterMs = { ["2"] = 600 },
})
expect(merged.highestChapter == 15 and merged.completionCount == 3, "stale session cannot regress")
expect(merged.collectedKeys.older and merged.collectedKeys.newer, "personal key union")
expect(merged.medals.Toad2 and merged.medals.Explorer4 and merged.assistedChapters["3"], "medal and assistance union")
expect(merged.bestRunMs == 10000 and merged.bestChapterMs["2"] == 400, "best times survive stale server")
print("profile schema tests passed (including concurrent monotonic merges)")
