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
  SaveCheckpoints = false, -- Kid Notes: flip to true when testing DataStore saves
  UseDataStore = false, -- keep off in Studio to avoid errors
  DataStoreName = "ObbyOfLegends_Checkpoints",
  -- Cycle through these until one preloads; swap in your own IDs if they error.
  MusicIds = {
    "rbxassetid://1843521234",
    "rbxassetid://1837468655",
    "rbxassetid://6065479763",
  },
  MaxPlayersPerServer = 12,
  ProgressRemote = "ObbyProgress",
  KeyRemote = "KeyProgress",
  FinaleRemote = "FinaleSpotlight",
  KeySpawnChance = 0.6,
}

return GameConfig
