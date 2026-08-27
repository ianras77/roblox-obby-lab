local GameConfig = {
  Title = "Toad's Great Escape",
  Subtitle = "A wild storybook obby inspired by The Wind in the Willows",
  StoryIntro = "Toad has one more brilliant idea. Sprint through the riverbank, hall, court, jail, woods, and home!",
  -- Kid Notes: change this seed to reshape the whole obby deterministically.
  Seed = 12345,
  Zones = 3,
  StagesPerZone = 6,
  StageSpacing = Vector3.new(55, 0, 0),
  ElevationPerZone = 10,
  AllowlistUserIds = { 0 }, -- Kid Notes: add your userId here to unlock /reseed, /rebuild, /stage
  DevCommandsEnabled = true,
  MaxDevSeed = 2147483647,
  MaxDevStage = 18,
  DevCommandCooldownSeconds = 2,
  MinimumTimeTrialSeconds = 30,
  Environment = "StudioDevelopment", -- StudioDevelopment, StudioSandbox, Staging, Production
  SaveCheckpoints = true, -- Environment controls whether the store can write.
  UseDataStore = true, -- StudioDevelopment is blocked by DataStoreServiceWrapper.
  AutosaveSeconds = 120,
  ActiveMechanicRadius = 220,
  EnableAnalytics = false,
  DataStoreName = "ToadsGreatEscape_Profile_v1",
  ProgressRemote = "ObbyProgress",
  KeyRemote = "KeyProgress",
  FinaleRemote = "FinaleSpotlight",
  AuthoredKeysPerChapter = 1,
}

return GameConfig
