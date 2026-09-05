--!strict

-- Adventure is the product baseline; Time Trial may tighten authored routes.
return {
  Adventure = {
    Early = { MinLandingWidth = 10, MaxGap = 4, ConveyorSpeed = 7, WindSpeed = 5, FallingDelay = 1.5 },
    Mid = { MinLandingWidth = 8, MaxGap = 6, ConveyorSpeed = 8, WindSpeed = 6, FallingDelay = 1.5 },
    Late = { MinLandingWidth = 7, MaxGap = 7.5, ConveyorSpeed = 10, WindSpeed = 8, FallingDelay = 1.5 },
  },
  TimeTrial = { ConveyorSpeed = 18, WindSpeed = 12, FallingDelay = 0.8 },
  Limits = { MovingPlatformPeakVelocity = 12, AdventureWindVelocity = 8, MinimumFallingDelay = 1.25 },
}
