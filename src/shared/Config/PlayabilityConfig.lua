--!strict

-- Adventure is the product baseline; Time Trial may tighten authored routes.
return {
  Adventure = {
    Early = { MinLandingWidth = 10, MaxGap = 8, ConveyorSpeed = 7, WindSpeed = 5, FallingDelay = 1.5 },
    Mid = { MinLandingWidth = 8, MaxGap = 10, ConveyorSpeed = 8, WindSpeed = 6, FallingDelay = 1.1 },
    Late = { MinLandingWidth = 7, MaxGap = 12, ConveyorSpeed = 10, WindSpeed = 8, FallingDelay = 0.9 },
  },
  TimeTrial = { ConveyorSpeed = 18, WindSpeed = 12, FallingDelay = 0.8 },
  Limits = { MovingPlatformPeakVelocity = 12, AdventureWindVelocity = 8, MinimumFallingDelay = 0.8 },
}
