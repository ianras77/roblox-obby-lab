local WorldGenConfig = {
  StageTypes = {
    "Warmup",
    "BouncyClouds",
    "ToadHallGate",
    "ToadLibrary",
    "CaravanChase",
    "PubChaos",
    "JailBreak",
    "RiverBarge",
    "TrainTunnel",
    "SeesawGate",
    "CourtroomChaos",
    "MotorMadness",
    "WildWoods",
    "Warmup",
    "LaserGrid",
    "FinaleRing",
  },
  StageLengthMin = 40,
  StageLengthMax = 60,
  PlatformSize = Vector3.new(10, 1, 10),
  PathWidth = 22,
  CheckpointSize = Vector3.new(6, 1, 6),
  LaneLightSpacing = 12,
}

return WorldGenConfig
