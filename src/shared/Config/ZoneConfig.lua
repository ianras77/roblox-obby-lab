local ZoneConfig = {
  {
    Name = "Riverbank and Toad Hall",
    ThemeColor = Color3.fromRGB(105, 225, 165), -- mint, gold, sunny grass
    FogColor = Color3.fromRGB(244, 255, 246),
    Ambient = Color3.fromRGB(72, 130, 92),
    SkyColor = Color3.fromRGB(255, 252, 220),
    FogEnd = 340,
    ClockTime = 14,
    AmbientSoundKey = "zone_1_ambience", -- verify in Creator Hub before release
  },
  {
    Name = "Trouble and Escape",
    ThemeColor = Color3.fromRGB(255, 195, 90), -- amber, paper, courtroom lamps
    FogColor = Color3.fromRGB(255, 244, 218),
    Ambient = Color3.fromRGB(145, 100, 70),
    SkyColor = Color3.fromRGB(255, 238, 202),
    FogEnd = 340,
    ClockTime = 16,
    AmbientSoundKey = "zone_2_ambience", -- verify in Creator Hub before release
  },
  {
    Name = "Wild Wood Homecoming",
    ThemeColor = Color3.fromRGB(120, 205, 255), -- teal, lantern blue, party lights
    FogColor = Color3.fromRGB(229, 245, 255),
    Ambient = Color3.fromRGB(62, 100, 145),
    SkyColor = Color3.fromRGB(235, 250, 255),
    FogEnd = 350,
    ClockTime = 17,
    AmbientSoundKey = "zone_3_ambience", -- verify in Creator Hub before release
  },
}

return ZoneConfig
