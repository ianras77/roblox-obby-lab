local ObstacleConfig = {
  -- Kid Notes: tweak these speeds to make the obby wilder or calmer.
  MovingPlatformSpeed = 7, -- legacy compatibility; new content uses PeriodSeconds
  MovingPlatformPeriod = 4,
  MovingPlatformAmplitude = 5,
  RotatorSpeed = math.rad(32),
  TimedTileInterval = 2.5,
  ConveyorSpeed = 8,
  BouncePower = 58,
  LavaRiseSpeed = 6,
  WindForce = 8,
  LaserCycleTime = 3,
  FallingPlatformDelay = 1.35,
  FallingPlatformRespawn = 5,
}

return ObstacleConfig
