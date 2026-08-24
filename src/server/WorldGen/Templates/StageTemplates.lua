local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Build = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Build"))
local ObstacleConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ObstacleConfig"))
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))
local AssetRegistry = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AssetRegistry"))

local StageTemplates = {}

local function difficultyFactor(ctx, minFactor, maxFactor)
  local diff = ctx.difficulty or 0.5
  return (minFactor or 1) + ((maxFactor or 1) - (minFactor or 1)) * diff
end

local function scaleSpeed(ctx, base, minFactor, maxFactor)
  return base * difficultyFactor(ctx, minFactor, maxFactor)
end

local function basePlatform(parent, cframe, color, size)
  local part = Build.part({
    Name = "Platform",
    Parent = parent,
    CFrame = cframe,
    Size = size or WorldGenConfig.PlatformSize,
    Color = color,
    Material = Enum.Material.Concrete,
  })
  return part
end

local function addSign(parent, cframe, text)
  local sign = Build.part({
    Name = "Sign",
    Parent = parent,
    CFrame = cframe,
    Size = Vector3.new(4, 5, 1),
    Color = Color3.fromRGB(60, 40, 20),
    Material = Enum.Material.WoodPlanks,
  })
  local billboard = Instance.new("BillboardGui")
  billboard.Size = UDim2.fromOffset(160, 60)
  billboard.StudsOffset = Vector3.new(0, 2.5, 0)
  billboard.AlwaysOnTop = true
  billboard.Adornee = sign
  billboard.Parent = sign

  local label = Instance.new("TextLabel")
  label.BackgroundTransparency = 1
  label.Text = text
  label.Font = Enum.Font.GothamBold
  label.TextScaled = true
  label.TextColor3 = Color3.new(1, 1, 1)
  label.Parent = billboard
  Build.tag(sign, { "Beacon" })
  return sign
end

local function addBillboard(parent, target, text, color)
  local billboard = Instance.new("BillboardGui")
  billboard.Size = UDim2.fromOffset(220, 100)
  billboard.AlwaysOnTop = true
  billboard.StudsOffset = Vector3.new(0, 4, 0)
  billboard.Adornee = target
  billboard.Parent = parent

  local label = Instance.new("TextLabel")
  label.BackgroundTransparency = 0.15
  label.BackgroundColor3 = color or Color3.fromRGB(255, 240, 200)
  label.BorderSizePixel = 0
  label.Text = text
  label.Font = Enum.Font.GothamBold
  label.TextScaled = true
  label.TextColor3 = Color3.fromRGB(35, 25, 20)
  label.Parent = billboard
  return billboard
end

-- Classic warmup keeps things approachable
function StageTemplates.Warmup(ctx)
  local model = Build.model("Stage_Warmup", ctx.parent)
  local step = WorldGenConfig.PlatformSize.X + 4
  for i = 0, 4 do
    basePlatform(model, ctx.origin * CFrame.new(step * i, 0, 0), ctx.color)
  end
  addSign(model, ctx.origin * CFrame.new(step * 2, 3, -6), "Welcome to Toad Hall!")
  addSign(model, ctx.origin * CFrame.new(step * 3, 6, 6), "Sprint + space to long-jump!")
  -- lane lights
  for i = 0, 4 do
    local light = Build.part({
      Name = "LaneLight",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(step * i, 2, -WorldGenConfig.PathWidth * 0.4),
      Size = Vector3.new(0.6, 0.6, 0.6),
      Color = Color3.fromRGB(255, 255, 120),
      Material = Enum.Material.Neon,
      Anchored = true,
      Tags = { "Beacon" },
    })
    light.CanCollide = false

    local sparkle = Instance.new("ParticleEmitter")
    sparkle.Texture = AssetRegistry.getApprovedId("sparkle_particle")
    sparkle.Rate = 12
    sparkle.Speed = NumberRange.new(2, 4)
    sparkle.Lifetime = NumberRange.new(0.4, 0.8)
    sparkle.Parent = light
  end

  -- floating neon balloons
  for i = 0, 3 do
    local balloon = Build.part({
      Name = "Balloon",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(step * i, 10, (i % 2 == 0) and 6 or -6),
      Size = Vector3.new(3, 4, 3),
      Color = Color3.fromRGB(255, 190, 140),
      Material = Enum.Material.Neon,
    })
    balloon.Anchored = true
    balloon.Transparency = 0.2
    addBillboard(model, balloon, "Riverbank Welcome", Color3.fromRGB(255, 230, 200))
  end
  return model, ctx.origin * CFrame.new(step * 5, 0, 0)
end

-- Stage: Bouncy Clouds — playful early hook with soft visuals
function StageTemplates.BouncyClouds(ctx)
  local model = Build.model("Stage_BouncyClouds", ctx.parent)
  local span = WorldGenConfig.StageLengthMin

  local function cloud(cf, size, power)
    local cloudPart = Build.part({
      Name = "Cloud",
      Parent = model,
      CFrame = cf,
      Size = size,
      Color = Color3.fromRGB(245, 245, 255),
      Material = Enum.Material.ForceField,
      Tags = { "BouncePad", "Beacon" },
      Attributes = { Power = power or ObstacleConfig.BouncePower * 1.4 },
    })
    cloudPart.Transparency = 0.25
    local puff = Instance.new("ParticleEmitter")
    puff.Texture = AssetRegistry.getApprovedId("soft_particle")
    puff.Lifetime = NumberRange.new(0.8, 1.2)
    puff.Speed = NumberRange.new(2, 4)
    puff.Rate = 12
    puff.Parent = cloudPart
    return cloudPart
  end

  local step = span / 6
  for i = 0, 6 do
    local offsetY = (i % 2 == 0) and 3 or 7
    cloud(ctx.origin * CFrame.new(step * i, offsetY, (i % 3 - 1) * 4), Vector3.new(10, 1.4, 10), 80 + i * 4)
  end

  -- crumbly clouds that physically drop after you land on them
  for i = 1, 3 do
    local crumble = Build.part({
      Name = "CrumblyCloud",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(step * (i * 2 + 1), 2.2, (i % 2 == 0) and 5 or -5),
      Size = Vector3.new(8, 1, 8),
      Color = Color3.fromRGB(235, 240, 255),
      Material = Enum.Material.ForceField,
      Tags = { "FallingPlatform", "Beacon" },
      Attributes = {
        DropDelay = ObstacleConfig.FallingPlatformDelay,
        RespawnTime = ObstacleConfig.FallingPlatformRespawn,
      },
    })
    crumble.Transparency = 0.15
  end

  -- drifting glow orbs overhead
  for i = 0, 5 do
    local orb = Build.part({
      Name = "GlowOrb",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(step * i, 12 + i, 0),
      Size = Vector3.new(1.2, 1.2, 1.2),
      Color = Color3.fromRGB(255, 220, 140),
      Material = Enum.Material.Neon,
    })
    orb.Anchored = true
    local pl = Instance.new("PointLight")
    pl.Range = 16
    pl.Brightness = 3
    pl.Color = Color3.fromRGB(255, 220, 160)
    pl.Parent = orb
  end

  local banner = Build.part({
    Name = "FloatBanner",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(span * 0.4, 9, -6),
    Size = Vector3.new(6, 4, 1),
    Color = Color3.fromRGB(255, 200, 120),
    Material = Enum.Material.Neon,
  })
  banner.CanCollide = false
  local billboard = Instance.new("BillboardGui")
  billboard.Size = UDim2.fromOffset(200, 80)
  billboard.AlwaysOnTop = true
  billboard.StudsOffset = Vector3.new(0, 1, 0)
  billboard.Adornee = banner
  billboard.Parent = banner
  local label = Instance.new("TextLabel")
  label.BackgroundTransparency = 1
  label.Text = "Toad says: BOING!"
  label.Font = Enum.Font.GothamBold
  label.TextScaled = true
  label.TextColor3 = Color3.fromRGB(45, 30, 10)
  label.Parent = billboard

  return model, ctx.origin * CFrame.new(span + 10, 0, 0)
end

-- Stage: Toad Library crash — swinging armor + popping books
function StageTemplates.ToadLibrary(ctx)
  local model = Build.model("Stage_ToadLibrary", ctx.parent)
  local length = WorldGenConfig.StageLengthMin
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(length, 1, WorldGenConfig.PathWidth))

  for i = 0, 3 do
    local armor = Build.part({
      Name = "Armor",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 4) * i + 6, 5, (i % 2 == 0) and -6 or 6),
      Size = Vector3.new(2, 8, 1),
      Color = Color3.fromRGB(160, 150, 120),
      Material = Enum.Material.Metal,
      Tags = { "Rotator", "KillBrick" },
      Attributes = { RotSpeed = ObstacleConfig.RotatorSpeed * 1.6 },
    })
    armor.CanCollide = false
  end

  for i = 1, 4 do
    local shelf = Build.part({
      Name = "BookBurst",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 5) * i, 1.2, (i % 2 == 0) and 4 or -4),
      Size = Vector3.new(4, 0.6, 4),
      Color = Color3.fromRGB(200, 180, 120),
      Material = Enum.Material.WoodPlanks,
      Tags = { "TimedTile" },
      Attributes = { Cycle = ObstacleConfig.TimedTileInterval * 0.8 },
    })
    shelf.CanCollide = true
  end

  local banner = Build.part({
    Name = "ManiaSign",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.45, 7, -WorldGenConfig.PathWidth * 0.45),
    Size = Vector3.new(6, 4, 1),
    Color = Color3.fromRGB(255, 220, 140),
    Material = Enum.Material.Neon,
  })
  banner.CanCollide = false
  addBillboard(model, banner, "Toad's Reading Room ->", Color3.fromRGB(255, 240, 200))

  return model, ctx.origin * CFrame.new(length + 10, 0, 0)
end

-- Stage 1: Toad Hall Gate with a rotating sweeper
function StageTemplates.ToadHallGate(ctx)
  local model = Build.model("Stage_ToadHallGate", ctx.parent)
  local width = 20
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(width, 1, WorldGenConfig.PathWidth))
  addSign(model, ctx.origin * CFrame.new(width * 0.25, 4, -WorldGenConfig.PathWidth * 0.3), "TOAD HALL")
  local arch = Build.part({
    Name = "Arch",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(width * 0.5, 6, 0),
    Size = Vector3.new(2, 12, WorldGenConfig.PathWidth - 2),
    Color = Color3.fromRGB(90, 70, 40),
    Material = Enum.Material.Wood,
  })
  arch.CanCollide = false
  Build.tag(arch, { "Beacon" })

  Build.part({
    Name = "Sweeper",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(width * 0.5, 2, 0),
    Size = Vector3.new(WorldGenConfig.PathWidth, 1, 1),
    Color = Color3.fromRGB(255, 180, 60),
    Tags = { "Rotator", "KillBrick" },
    Attributes = { RotSpeed = scaleSpeed(ctx, ObstacleConfig.RotatorSpeed * 1.2, 0.55, 1.25) },
  })
  -- portrait board
  local portrait = Build.part({
    Name = "ToadPortrait",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(width * 0.7, 6, WorldGenConfig.PathWidth * 0.55),
    Size = Vector3.new(6, 6, 1),
    Color = Color3.fromRGB(255, 240, 200),
    Material = Enum.Material.Neon,
  })
  portrait.CanCollide = false
  local decal = Instance.new("Decal")
  decal.Texture = AssetRegistry.getApprovedId("frog_decal") -- kid-safe frog decal
  decal.Face = Enum.NormalId.Front
  decal.Parent = portrait
  return model, ctx.origin * CFrame.new(width + 12, 0, 0)
end

-- Stage 2: Caravan Chase with conveyors and hops
function StageTemplates.CaravanChase(ctx)
  local model = Build.model("Stage_CaravanChase", ctx.parent)
  local span = WorldGenConfig.StageLengthMin
  local conveyor = basePlatform(
    model,
    ctx.origin * CFrame.new(span * 0.5, 0, 0),
    ctx.color,
    Vector3.new(span, 1, WorldGenConfig.PathWidth)
  )
  conveyor:SetAttribute("Speed", scaleSpeed(ctx, ObstacleConfig.ConveyorSpeed * 1.2, 0.6, 1.4))
  Build.tag(conveyor, { "Conveyor" })

  for i = 0, math.floor(span / WorldGenConfig.LaneLightSpacing) do
    local light = Build.part({
      Name = "LaneLight",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(WorldGenConfig.LaneLightSpacing * i, 2, -WorldGenConfig.PathWidth * 0.45),
      Size = Vector3.new(0.6, 0.6, 0.6),
      Color = Color3.fromRGB(255, 255, 140),
      Material = Enum.Material.Neon,
      Anchored = true,
      Tags = { "Beacon" },
    })
    light.CanCollide = false
  end

  for i = 1, 3 do
    local gap = Build.part({
      Name = "GapMarker",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((span / 4) * i, 3, 0),
      Size = Vector3.new(6, 0.5, WorldGenConfig.PathWidth - 6),
      Transparency = 0.3,
      Color = Color3.fromRGB(255, 230, 120),
      Material = Enum.Material.Neon,
    })
    gap.CanCollide = false
  end

  local wheel = Build.part({
    Name = "RunawayWheel",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(span * 0.3, 2, -WorldGenConfig.PathWidth * 0.4),
    Size = Vector3.new(2, 2, 2),
    Shape = Enum.PartType.Ball,
    Color = Color3.fromRGB(80, 80, 80),
    Tags = { "Rotator", "KillBrick" },
    Attributes = { RotSpeed = scaleSpeed(ctx, ObstacleConfig.RotatorSpeed * 2, 0.6, 1.6) },
  })
  wheel.Anchored = true

  return model, ctx.origin * CFrame.new(span + 10, 0, 0)
end

-- Stage 3: Jail Break with timed bars
function StageTemplates.JailBreak(ctx)
  local model = Build.model("Stage_JailBreak", ctx.parent)
  local length = WorldGenConfig.StageLengthMin
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(length, 1, WorldGenConfig.PathWidth - 4))
  for i = 1, 4 do
    local bar = Build.part({
      Name = "CellBar",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 5) * i, 4, 0),
      Size = Vector3.new(1, 8, WorldGenConfig.PathWidth - 6),
      Color = Color3.fromRGB(200, 200, 220),
      Material = Enum.Material.Metal,
      Tags = { "TimedTile", "KillBrick" },
      Attributes = {
        Cycle = ObstacleConfig.TimedTileInterval * (1 - 0.5 * difficultyFactor(ctx, 0, 1)),
      },
    })
    bar.CanCollide = true
  end
  for i = 0, math.floor(length / WorldGenConfig.LaneLightSpacing) do
    local light = Build.part({
      Name = "LaneLight",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(WorldGenConfig.LaneLightSpacing * i, 2, WorldGenConfig.PathWidth * 0.45),
      Size = Vector3.new(0.6, 0.6, 0.6),
      Color = Color3.fromRGB(180, 220, 255),
      Material = Enum.Material.Neon,
      Anchored = true,
      Tags = { "Beacon" },
    })
    light.CanCollide = false
  end
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

-- Stage 4: River Barge boats over toxic water
function StageTemplates.RiverBarge(ctx)
  local model = Build.model("Stage_RiverBarge", ctx.parent)
  local span = WorldGenConfig.StageLengthMax
  local water = Build.part({
    Name = "Water",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(span * 0.5, -3, 0),
    Size = Vector3.new(span, 6, WorldGenConfig.PathWidth + 10),
    Color = Color3.fromRGB(40, 90, 170),
    Material = Enum.Material.Water,
    Tags = { "KillBrick" },
  })
  water.Transparency = 0.3
  local bubbles = Instance.new("ParticleEmitter")
  bubbles.Texture = AssetRegistry.getApprovedId("soft_particle")
  bubbles.Rate = 12
  bubbles.Lifetime = NumberRange.new(0.6, 1)
  bubbles.Speed = NumberRange.new(3, 6)
  bubbles.Rotation = NumberRange.new(-180, 180)
  bubbles.Parent = water

  for i = 1, 4 do
    local cframe = ctx.origin * CFrame.new((span / 5) * i, 0, (i % 2 == 0) and 6 or -6)
    local boat = basePlatform(model, cframe, Color3.fromRGB(180, 140, 90), Vector3.new(12, 1, 6))
    boat:SetAttribute("Amplitude", 8)
    boat:SetAttribute("Axis", Vector3.new(0, 0, 1))
    boat:SetAttribute("Speed", scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.6, 0.6, 1.4))
    Build.tag(boat, { "MovingPlatform" })
  end

  -- Safety stepping stones down the center so no dead-ends
  for i = 0, 5 do
    Build.part({
      Name = "Stone",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((span / 5) * i, 0.6, 0),
      Size = Vector3.new(4, 1, 4),
      Color = Color3.fromRGB(220, 220, 240),
      Material = Enum.Material.SmoothPlastic,
    })
  end

  for i = 0, math.floor(span / WorldGenConfig.LaneLightSpacing) do
    local light = Build.part({
      Name = "LaneLight",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(WorldGenConfig.LaneLightSpacing * i, 2, -WorldGenConfig.PathWidth * 0.45),
      Size = Vector3.new(0.6, 0.6, 0.6),
      Color = Color3.fromRGB(120, 200, 255),
      Material = Enum.Material.Neon,
      Anchored = true,
      Tags = { "Beacon" },
    })
    light.CanCollide = false
  end
  return model, ctx.origin * CFrame.new(span + 10, 0, 0)
end

-- Stage: Pub Chaos — barrels, spinning mugs, neon sign
function StageTemplates.PubChaos(ctx)
  local model = Build.model("Stage_PubChaos", ctx.parent)
  local length = WorldGenConfig.StageLengthMin
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(length, 1, WorldGenConfig.PathWidth))

  for i = 1, 5 do
    Build.part({
      Name = "Barrel",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 6) * i, 1.4, (i % 2 == 0) and 4 or -4),
      Size = Vector3.new(3, 3, 3),
      Color = Color3.fromRGB(130, 90, 60),
      Material = Enum.Material.Wood,
      Tags = { "Conveyor", "KillBrick" },
      Attributes = {
        Speed = scaleSpeed(
          ctx,
          (i % 2 == 0) and ObstacleConfig.ConveyorSpeed or -ObstacleConfig.ConveyorSpeed,
          0.6,
          1.5
        ),
      },
    })
  end

  for i = 0, 3 do
    local mug = Build.part({
      Name = "SpinMug",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 4) * i + 6, 6, 0),
      Size = Vector3.new(2, 2, 2),
      Color = Color3.fromRGB(255, 255, 200),
      Material = Enum.Material.Neon,
      Tags = { "Rotator", "KillBrick" },
      Attributes = { RotSpeed = scaleSpeed(ctx, ObstacleConfig.RotatorSpeed * 2.2, 0.6, 1.8) },
    })
    mug.Shape = Enum.PartType.Cylinder
    mug.CanCollide = false
  end

  local sign = Build.part({
    Name = "NeonSign",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.6, 8, -WorldGenConfig.PathWidth * 0.5),
    Size = Vector3.new(10, 4, 1),
    Color = Color3.fromRGB(255, 120, 160),
    Material = Enum.Material.Neon,
  })
  sign.CanCollide = false
  addBillboard(model, sign, "Toad's Tavern", Color3.fromRGB(255, 120, 180))

  return model, ctx.origin * CFrame.new(length + 12, 0, 0)
end

-- Stage: Train Tunnel — rolling spotlight train dodge
function StageTemplates.TrainTunnel(ctx)
  local model = Build.model("Stage_TrainTunnel", ctx.parent)
  local length = WorldGenConfig.StageLengthMax

  local tunnel = Build.part({
    Name = "Tunnel",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.5, 5, 0),
    Size = Vector3.new(length, 12, WorldGenConfig.PathWidth + 6),
    Color = Color3.fromRGB(40, 40, 50),
    Material = Enum.Material.Slate,
  })
  tunnel.Transparency = 0.6
  tunnel.CanCollide = false

  Build.part({
    Name = "Tracks",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.5, 0.2, 0),
    Size = Vector3.new(length, 0.4, 4),
    Color = Color3.fromRGB(120, 80, 60),
    Material = Enum.Material.Wood,
  })

  local train = Build.part({
    Name = "Train",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(-8, 2, 0),
    Size = Vector3.new(10, 4, 4),
    Color = Color3.fromRGB(255, 80, 80),
    Material = Enum.Material.Metal,
    Tags = { "MovingPlatform", "KillBrick" },
    Attributes = {
      Amplitude = length + 16,
      Speed = scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.4, 0.6, 1.5),
      Axis = Vector3.new(1, 0, 0),
      CarryPlayers = true,
    },
  })
  local headlight = Instance.new("PointLight")
  headlight.Range = 40
  headlight.Brightness = 6
  headlight.Color = Color3.fromRGB(255, 255, 200)
  headlight.Parent = train

  for i = 0, math.floor(length / WorldGenConfig.LaneLightSpacing) do
    local lantern = Build.part({
      Name = "Lantern",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(WorldGenConfig.LaneLightSpacing * i, 7, -WorldGenConfig.PathWidth * 0.45),
      Size = Vector3.new(0.6, 0.6, 0.6),
      Color = Color3.fromRGB(255, 230, 150),
      Material = Enum.Material.Neon,
      Anchored = true,
      Tags = { "Beacon" },
    })
    lantern.CanCollide = false
  end

  -- Telegraph the train and give players readable recovery pockets. The
  -- pockets sit outside the central track lane and are never required for
  -- forward progress.
  for i, pct in ipairs({ 0.24, 0.52, 0.8 }) do
    for _, side in ipairs({ -1, 1 }) do
      local alcove = basePlatform(
        model,
        ctx.origin * CFrame.new(length * pct, 1.2, side * (WorldGenConfig.PathWidth * 0.5 + 1.5)),
        Color3.fromRGB(75, 80, 92),
        Vector3.new(5, 0.8, 3.5)
      )
      alcove.Name = "TrainSafeAlcove"
      alcove.Material = Enum.Material.Slate
      local warning = Build.part({
        Name = "TrainWarningLamp",
        Parent = model,
        CFrame = ctx.origin * CFrame.new(length * pct, 4, side * (WorldGenConfig.PathWidth * 0.5 + 1.5)),
        Size = Vector3.new(1.2, 1.2, 1.2),
        Color = (i % 2 == 0) and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(120, 240, 255),
        Material = Enum.Material.Neon,
        Tags = { "Beacon" },
      })
      warning.CanCollide = false
    end
  end
  addSign(model, ctx.origin * CFrame.new(length * 0.18, 6, -WorldGenConfig.PathWidth * 0.5), "Listen for the signal")

  return model, ctx.origin * CFrame.new(length + 14, 0, 0)
end

-- Stage: SeesawGate (co-op pads open gate)
function StageTemplates.SeesawGate(ctx)
  local model = Build.model("Stage_SeesawGate", ctx.parent)
  local length = WorldGenConfig.StageLengthMin
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(length, 1, WorldGenConfig.PathWidth))

  local gateId = string.format("Gate_%03d", ctx.stageIndex or ctx.random:NextInteger(1000, 9999))

  Build.part({
    Name = "Gate",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.6, 3, 0),
    Size = Vector3.new(2, 8, WorldGenConfig.PathWidth - 4),
    Color = Color3.fromRGB(255, 120, 120),
    Material = Enum.Material.Neon,
    Anchored = true,
    Tags = { "Gate" },
    Attributes = { GateId = gateId },
  })

  local padA = Build.part({
    Name = "PadA",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.25, 0.5, WorldGenConfig.PathWidth * 0.35),
    Size = Vector3.new(6, 1, 6),
    Color = Color3.fromRGB(120, 200, 255),
    Material = Enum.Material.SmoothPlastic,
    Tags = { "PressurePad" },
    Attributes = { PadId = "A", GateId = gateId },
  })
  padA.Anchored = true

  local padB = Build.part({
    Name = "PadB",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.4, 0.5, -WorldGenConfig.PathWidth * 0.35),
    Size = Vector3.new(6, 1, 6),
    Color = Color3.fromRGB(120, 200, 255),
    Material = Enum.Material.SmoothPlastic,
    Tags = { "PressurePad" },
    Attributes = { PadId = "B", GateId = gateId },
  })
  padB.Anchored = true

  return model, ctx.origin * CFrame.new(length + 10, 0, 0)
end

-- Stage 5: Courtroom Chaos with a giant gavel and lasers
function StageTemplates.CourtroomChaos(ctx)
  local model = Build.model("Stage_CourtroomChaos", ctx.parent)
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(WorldGenConfig.StageLengthMin, 1, WorldGenConfig.PathWidth))
  Build.part({
    Name = "Gavel",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(WorldGenConfig.StageLengthMin * 0.5, 3, 0),
    Size = Vector3.new(WorldGenConfig.PathWidth, 1, 2),
    Color = Color3.fromRGB(120, 70, 40),
    Tags = { "Rotator", "KillBrick" },
    Attributes = { RotSpeed = ObstacleConfig.RotatorSpeed * 1.5 },
  })

  for i = 1, 3 do
    local beam = Build.part({
      Name = "Laser",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((WorldGenConfig.StageLengthMin / 4) * i, 2, 0),
      Size = Vector3.new(1, 1, WorldGenConfig.PathWidth),
      Color = Color3.fromRGB(255, 40, 40),
      Material = Enum.Material.Neon,
      Tags = { "Laser", "KillBrick" },
      Attributes = { Cycle = ObstacleConfig.LaserCycleTime * 0.8, Phase = i },
    })
    beam.CanCollide = false
    local sparks = Instance.new("ParticleEmitter")
    sparks.Texture = AssetRegistry.getApprovedId("sparkle_particle")
    sparks.Lifetime = NumberRange.new(0.3, 0.5)
    sparks.Speed = NumberRange.new(4, 8)
    sparks.Rate = 16
    sparks.Enabled = false
    sparks.Parent = beam
  end

  -- rickety benches that drop if you linger; adds a physics moment between lasers
  for i = 1, 2 do
    local bench = Build.part({
      Name = "Bench",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((WorldGenConfig.StageLengthMin / 3) * i + 6, 1.4, (i % 2 == 0) and 5 or -5),
      Size = Vector3.new(8, 0.8, 3),
      Color = Color3.fromRGB(110, 70, 40),
      Material = Enum.Material.Wood,
      Tags = { "FallingPlatform" },
      Attributes = {
        DropDelay = ObstacleConfig.FallingPlatformDelay * 0.6,
        RespawnTime = ObstacleConfig.FallingPlatformRespawn,
      },
    })
    bench.Anchored = true
  end

  return model, ctx.origin * CFrame.new(WorldGenConfig.StageLengthMin + 12, 0, 0)
end

-- Stage 6: Motor Madness speed strip
function StageTemplates.MotorMadness(ctx)
  local model = Build.model("Stage_MotorMadness", ctx.parent)
  local span = WorldGenConfig.StageLengthMin
  local road = basePlatform(
    model,
    ctx.origin * CFrame.new(span * 0.5, 0, 0),
    ctx.color,
    Vector3.new(span, 1, WorldGenConfig.PathWidth)
  )
  road.Material = Enum.Material.Asphalt
  road:SetAttribute("Speed", scaleSpeed(ctx, ObstacleConfig.ConveyorSpeed * 1.6, 0.6, 1.6))
  Build.tag(road, { "Conveyor" })

  -- Narrow sidewalk on the side for a safe (slower) path
  local sidewalk = basePlatform(
    model,
    ctx.origin * CFrame.new(span * 0.5, 0.4, WorldGenConfig.PathWidth * 0.5),
    Color3.fromRGB(240, 240, 240),
    Vector3.new(span, 0.4, 4)
  )
  sidewalk.Material = Enum.Material.SmoothPlastic
  sidewalk.CanCollide = true

  -- loose traffic cones you can nudge (pure physics, no scripting)
  for i = 1, 5 do
    local cone = Build.part({
      Name = "TrafficCone",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((span / 6) * i, 1, -WorldGenConfig.PathWidth * 0.35),
      Size = Vector3.new(1.5, 2.6, 1.5),
      Color = Color3.fromRGB(255, 140, 40),
      Material = Enum.Material.Plastic,
      Anchored = true,
    })
    cone.Shape = Enum.PartType.Cylinder
  end

  Build.part({
    Name = "StreetSign",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(span * 0.7, 5, 0),
    Size = Vector3.new(1, 10, 1),
    Color = Color3.fromRGB(40, 120, 40),
    Tags = { "Rotator", "KillBrick", "Beacon" },
    Attributes = { RotSpeed = ObstacleConfig.RotatorSpeed },
  })

  return model, ctx.origin * CFrame.new(span + 10, 0, 0)
end

-- Stage 7: Wild Woods wind tunnel
function StageTemplates.WildWoods(ctx)
  local model = Build.model("Stage_WildWoods", ctx.parent)
  local length = WorldGenConfig.StageLengthMin
  basePlatform(model, ctx.origin, ctx.color)
  local wind = Build.part({
    Name = "WindZone",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.5, 6, 0),
    Size = Vector3.new(length, 12, WorldGenConfig.PathWidth),
    Transparency = 0.7,
    Color = Color3.fromRGB(180, 255, 220),
    Material = Enum.Material.Glass,
    Tags = { "WindZone" },
    Attributes = { Force = ObstacleConfig.WindForce * 1.2 },
  })
  wind.Anchored = true
  wind.CanCollide = false
  local leaves = Instance.new("ParticleEmitter")
  leaves.Texture = AssetRegistry.getApprovedId("leaf_particle")
  leaves.Rate = 18
  leaves.Lifetime = NumberRange.new(1, 1.4)
  leaves.Speed = NumberRange.new(6, 10)
  leaves.Rotation = NumberRange.new(-180, 180)
  leaves.Parent = wind

  for i = 1, 3 do
    local tree = Build.part({
      Name = "Tree",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 3) * i, 6, WorldGenConfig.PathWidth * 0.5),
      Size = Vector3.new(2, 12, 2),
      Color = Color3.fromRGB(90, 60, 30),
      Material = Enum.Material.Wood,
    })
    tree.CanCollide = false
    local crown = Build.part({
      Name = "TreeCrown",
      Parent = model,
      CFrame = tree.CFrame * CFrame.new(0, 7, 0),
      Size = Vector3.new(8, 4, 8),
      Color = Color3.fromRGB(120, 200, 255),
      Material = Enum.Material.Neon,
    })
    crown.Anchored = true
    crown.CanCollide = false
  end

  -- Floating logs that sway sideways with the wind to teach motion reading
  for i = 1, 3 do
    local log = Build.part({
      Name = "Log",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 4) * i, 1.5, (i % 2 == 0) and 6 or -6),
      Size = Vector3.new(10, 1, 3),
      Color = Color3.fromRGB(120, 80, 40),
      Material = Enum.Material.Wood,
      Tags = { "MovingPlatform" },
      Attributes = {
        Amplitude = 5,
        Speed = scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.55, 0.7, 1.5),
        Axis = Vector3.new(0, 0, 1),
        CarryPlayers = true,
        Phase = (i - 1) * math.pi / 2,
      },
    })
    log.Shape = Enum.PartType.Cylinder
  end

  -- Rope-suspended lanterns that actually swing with physics
  for i = 1, 2 do
    local anchor = Build.part({
      Name = "LanternAnchor",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 2) + (i == 1 and -8 or 8), 12, 0),
      Size = Vector3.new(2, 0.4, 2),
      Color = Color3.fromRGB(200, 220, 255),
      Anchored = true,
      Transparency = 1,
      CanCollide = false,
    })
    local lantern = Build.part({
      Name = "SwingLantern",
      Parent = model,
      CFrame = anchor.CFrame * CFrame.new(0, -6, 0),
      Size = Vector3.new(1.2, 2, 1.2),
      Color = Color3.fromRGB(255, 200, 120),
      Material = Enum.Material.Neon,
      Anchored = false,
      Tags = { "Beacon" },
      Attributes = { PhysicsDecor = true },
    })
    local light = Instance.new("PointLight")
    light.Range = 16
    light.Brightness = 3
    light.Color = Color3.fromRGB(255, 210, 150)
    light.Parent = lantern

    local top = Instance.new("Attachment")
    top.Parent = anchor
    local bottom = Instance.new("Attachment")
    bottom.Parent = lantern
    local rope = Instance.new("RopeConstraint")
    rope.Attachment0 = top
    rope.Attachment1 = bottom
    rope.Length = 6
    rope.Visible = true
    rope.Thickness = 0.08
    rope.Parent = lantern

    lantern.AssemblyLinearVelocity = Vector3.new((i == 1) and 10 or -10, 0, 6) -- kick to start swinging
  end

  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

-- Finale ring kept for celebration
function StageTemplates.FinaleRing(ctx)
  local model = Build.model("Stage_FinaleRing", ctx.parent)
  local radius = 20
  local steps = 12
  for i = 1, steps do
    local angle = (math.pi * 2 / steps) * i
    local x = radius * math.cos(angle)
    local z = radius * math.sin(angle)
    basePlatform(model, ctx.origin * CFrame.new(x, 0, z), ctx.color)
  end
  local emitter = Instance.new("ParticleEmitter")
  emitter.Texture = AssetRegistry.getApprovedId("finale_firework")
  emitter.Rate = 24
  emitter.Lifetime = NumberRange.new(1, 1.5)
  emitter.Speed = NumberRange.new(25, 35)
  emitter.Parent = model

  local confetti = Instance.new("ParticleEmitter")
  confetti.Texture = AssetRegistry.getApprovedId("confetti_particle")
  confetti.Rate = 40
  confetti.Lifetime = NumberRange.new(1, 1.2)
  confetti.Speed = NumberRange.new(12, 16)
  confetti.Rotation = NumberRange.new(-180, 180)
  confetti.Parent = model
  return model, ctx.origin * CFrame.new(radius * 2 + 20, 0, 0)
end

local function addPathLights(parent, origin, length, color, zOffset)
  local count = math.max(2, math.floor(length / WorldGenConfig.LaneLightSpacing))
  for i = 0, count do
    local light = Build.part({
      Name = "StoryLantern",
      Parent = parent,
      CFrame = origin * CFrame.new((length / count) * i, 2.5, zOffset or -WorldGenConfig.PathWidth * 0.42),
      Size = Vector3.new(0.7, 0.7, 0.7),
      Color = color,
      Material = Enum.Material.Neon,
      Tags = { "Beacon" },
    })
    light.CanCollide = false

    local glow = Instance.new("PointLight")
    glow.Range = 14
    glow.Brightness = 2.6
    glow.Color = color
    glow.Parent = light
  end
end

local function addSparkles(part, color, rate)
  local sparkles = Instance.new("ParticleEmitter")
  sparkles.Texture = AssetRegistry.getApprovedId("soft_particle")
  sparkles.Rate = rate or 10
  sparkles.Lifetime = NumberRange.new(0.6, 1.1)
  sparkles.Speed = NumberRange.new(2, 5)
  sparkles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
  sparkles.Parent = part
  return sparkles
end

local function addArch(parent, origin, name, color)
  local left = Build.part({
    Name = name .. "LeftPost",
    Parent = parent,
    CFrame = origin * CFrame.new(0, 5, -WorldGenConfig.PathWidth * 0.48),
    Size = Vector3.new(2, 10, 2),
    Color = color,
    Material = Enum.Material.WoodPlanks,
    Tags = { "Beacon" },
  })
  left.CanCollide = false

  local right = Build.part({
    Name = name .. "RightPost",
    Parent = parent,
    CFrame = origin * CFrame.new(0, 5, WorldGenConfig.PathWidth * 0.48),
    Size = Vector3.new(2, 10, 2),
    Color = color,
    Material = Enum.Material.WoodPlanks,
    Tags = { "Beacon" },
  })
  right.CanCollide = false

  local top = Build.part({
    Name = name .. "Top",
    Parent = parent,
    CFrame = origin * CFrame.new(0, 10, 0),
    Size = Vector3.new(3, 2, WorldGenConfig.PathWidth + 3),
    Color = color:Lerp(Color3.fromRGB(255, 235, 150), 0.35),
    Material = Enum.Material.WoodPlanks,
    Tags = { "Beacon" },
  })
  top.CanCollide = false
  addBillboard(parent, top, name, Color3.fromRGB(255, 238, 185))
end

function StageTemplates.RiverbankWelcome(ctx)
  local model = Build.model("Stage_RiverbankWelcome", ctx.parent)
  local step = 13
  local length = step * 6

  local waterLeft = Build.part({
    Name = "FriendlyRiverLeft",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.5, -1.2, -WorldGenConfig.PathWidth * 0.74),
    Size = Vector3.new(length + 18, 2, 7),
    Color = Color3.fromRGB(75, 180, 255),
    Material = Enum.Material.Glass,
  })
  waterLeft.Transparency = 0.35
  waterLeft.CanCollide = false

  local waterRight = waterLeft:Clone()
  waterRight.Name = "FriendlyRiverRight"
  waterRight.CFrame = ctx.origin * CFrame.new(length * 0.5, -1.2, WorldGenConfig.PathWidth * 0.74)
  waterRight.Parent = model

  for i = 0, 6 do
    local padColor = (i % 2 == 0) and Color3.fromRGB(110, 235, 150) or Color3.fromRGB(255, 222, 112)
    local pad = basePlatform(model, ctx.origin * CFrame.new(step * i, 0, 0), padColor, Vector3.new(11, 1, 11))
    pad.Material = Enum.Material.Grass
    addSparkles(pad, Color3.fromRGB(255, 250, 170), 4)
  end

  addSign(model, ctx.origin * CFrame.new(8, 4, -7), "Riverbank start")
  addSign(model, ctx.origin * CFrame.new(34, 6, 7), "Toad has a plan!")
  addPathLights(model, ctx.origin, length, Color3.fromRGB(255, 245, 150), -WorldGenConfig.PathWidth * 0.45)

  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

function StageTemplates.MoleBurrowBounce(ctx)
  local model = Build.model("Stage_MoleBurrowBounce", ctx.parent)
  local length = WorldGenConfig.StageLengthMin + 14
  local step = length / 6

  for i = 0, 6 do
    local hill = Build.part({
      Name = "MoleHillBounce",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(step * i, (i % 2 == 0) and 2.4 or 5.2, (i % 3 - 1) * 3.5),
      Size = Vector3.new(10, 1.5, 10),
      Color = (i % 2 == 0) and Color3.fromRGB(145, 105, 70) or Color3.fromRGB(180, 145, 90),
      Material = Enum.Material.Ground,
      Tags = { "BouncePad", "Beacon" },
      Attributes = { Power = ObstacleConfig.BouncePower * (1.1 + i * 0.04) },
    })
    hill.Transparency = 0.05
    addSparkles(hill, Color3.fromRGB(255, 236, 170), 8)
  end

  for i = 1, 3 do
    local crumbly = Build.part({
      Name = "CrumblyBurrowBridge",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(step * (i * 2 - 0.5), 1.2, (i % 2 == 0) and 5 or -5),
      Size = Vector3.new(8, 0.8, 8),
      Color = Color3.fromRGB(205, 170, 112),
      Material = Enum.Material.Ground,
      Tags = { "FallingPlatform", "Beacon" },
      Attributes = {
        DropDelay = ObstacleConfig.FallingPlatformDelay,
        RespawnTime = ObstacleConfig.FallingPlatformRespawn,
      },
    })
    crumbly.Anchored = true
  end

  addSign(model, ctx.origin * CFrame.new(8, 6, -6), "Mole says: bounce!")
  addPathLights(model, ctx.origin, length, Color3.fromRGB(255, 210, 130), WorldGenConfig.PathWidth * 0.44)
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

function StageTemplates.RattyRiverStones(ctx)
  local model = Build.model("Stage_RattyRiverStones", ctx.parent)
  local length = WorldGenConfig.StageLengthMax

  local river = Build.part({
    Name = "DeepBlueRiver",
    Parent = model,
    CFrame = ctx.origin * CFrame.new(length * 0.5, -2.7, 0),
    Size = Vector3.new(length + 18, 5, WorldGenConfig.PathWidth + 12),
    Color = Color3.fromRGB(35, 120, 230),
    Material = Enum.Material.Water,
    Tags = { "KillBrick" },
  })
  river.Transparency = 0.25
  addSparkles(river, Color3.fromRGB(145, 220, 255), 16)

  for i = 0, 6 do
    local stone = Build.part({
      Name = "RiverStone",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 6) * i, 0.4, (i % 2 == 0) and -4 or 4),
      Size = Vector3.new(8, 1.2, 7),
      Color = Color3.fromRGB(220, 224, 210),
      Material = Enum.Material.Slate,
      Tags = { "Beacon" },
    })
    stone.Shape = Enum.PartType.Cylinder
  end

  for i = 1, 3 do
    local leaf = Build.part({
      Name = "SwayingLilyPad",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 4) * i, 1.1, 0),
      Size = Vector3.new(9, 1, 9),
      Color = Color3.fromRGB(80, 220, 120),
      Material = Enum.Material.Grass,
      Tags = { "MovingPlatform", "Beacon" },
      Attributes = {
        Amplitude = 5,
        Speed = scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.45, 0.7, 1.3),
        Axis = Vector3.new(0, 0, 1),
        CarryPlayers = true,
        Phase = i,
      },
    })
    leaf.Shape = Enum.PartType.Cylinder
  end

  addSign(model, ctx.origin * CFrame.new(8, 5, -8), "Ratty's river route")
  addPathLights(model, ctx.origin, length, Color3.fromRGB(120, 235, 255), -WorldGenConfig.PathWidth * 0.5)
  return model, ctx.origin * CFrame.new(length + 10, 0, 0)
end

function StageTemplates.LibraryTumble(ctx)
  local model, endCFrame = StageTemplates.ToadLibrary(ctx)
  addSign(model, ctx.origin * CFrame.new(10, 8, 0), "Books are bouncing!")
  return model, endCFrame
end

function StageTemplates.RunawayCaravan(ctx)
  local model, endCFrame = StageTemplates.CaravanChase(ctx)
  addSign(model, ctx.origin * CFrame.new(12, 6, 7), "Runaway caravan!")
  return model, endCFrame
end

function StageTemplates.TavernBarrelHop(ctx)
  local model, endCFrame = StageTemplates.PubChaos(ctx)
  local length = WorldGenConfig.StageLengthMax
  for i = 1, 4 do
    local barrel = Build.part({
      Name = "TavernBarrel",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(length * (0.18 + i * 0.16), 2.2, (i % 2 == 0) and -4 or 4),
      Size = Vector3.new(3.5, 3.5, 3.5),
      Color = Color3.fromRGB(139, 86, 45),
      Material = Enum.Material.WoodPlanks,
      Tags = { "Rotator", "Beacon" },
      Attributes = { RotSpeed = scaleSpeed(ctx, ObstacleConfig.RotatorSpeed * 0.8, 0.7, 1.25) },
    })
    barrel.Shape = Enum.PartType.Cylinder
    barrel.Orientation = Vector3.new(0, 0, 90)
    barrel.CanCollide = false
    addSparkles(barrel, Color3.fromRGB(255, 210, 120), 3)
  end
  addSign(model, ctx.origin * CFrame.new(8, 6, -7), "Barrel hop!")
  return model, endCFrame
end

function StageTemplates.JailbreakBars(ctx)
  local model, endCFrame = StageTemplates.JailBreak(ctx)
  addSign(model, ctx.origin * CFrame.new(8, 7, -7), "Wait for the bars")
  return model, endCFrame
end

function StageTemplates.LaundryCartEscape(ctx)
  local model = Build.model("Stage_LaundryCartEscape", ctx.parent)
  local length = WorldGenConfig.StageLengthMin + 18

  local floor = basePlatform(
    model,
    ctx.origin * CFrame.new(length * 0.5, 0, 0),
    Color3.fromRGB(240, 230, 205),
    Vector3.new(length, 1, WorldGenConfig.PathWidth)
  )
  floor.Material = Enum.Material.WoodPlanks

  -- This chapter's signature ride is a guided, server-controlled cart. The
  -- floor gives players a safe recovery route if they miss the boarding seat.
  Build.cart(ctx.origin * CFrame.new(5, 1.5, 0), model, length + 8)

  for i = 1, 4 do
    local sheet = Build.part({
      Name = "FlutteringSheet",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 5) * i, 4, 0),
      Size = Vector3.new(1, 7, WorldGenConfig.PathWidth - 4),
      Color = (i % 2 == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 225, 255),
      Material = Enum.Material.Fabric,
      Tags = { "TimedTile" },
      Attributes = { Cycle = ObstacleConfig.TimedTileInterval * 0.75 + i * 0.1 },
    })
    sheet.CanCollide = true
  end

  for i = 1, 3 do
    local basket = Build.part({
      Name = "LaundryBasketRide",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 4) * i, 1.6, (i % 2 == 0) and 5 or -5),
      Size = Vector3.new(8, 1.2, 6),
      Color = Color3.fromRGB(170, 115, 70),
      Material = Enum.Material.WoodPlanks,
      Tags = { "MovingPlatform", "Beacon" },
      Attributes = {
        Amplitude = 5,
        Speed = scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.5, 0.8, 1.5),
        Axis = Vector3.new(0, 0, 1),
        CarryPlayers = true,
        Phase = i * 0.8,
      },
    })
    addSparkles(basket, Color3.fromRGB(255, 255, 210), 5)
  end

  addSign(model, ctx.origin * CFrame.new(9, 6, -7), "Laundry cart escape")
  addPathLights(model, ctx.origin, length, Color3.fromRGB(255, 245, 180), WorldGenConfig.PathWidth * 0.45)
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

function StageTemplates.BargeCrossing(ctx)
  local model, endCFrame = StageTemplates.RiverBarge(ctx)
  local span = WorldGenConfig.StageLengthMax
  for i = 1, 3 do
    local cargo = Build.part({
      Name = "BargeCargoCrate",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(span * (0.2 + i * 0.18), 2.1, (i % 2 == 0) and 5 or -5),
      Size = Vector3.new(4, 3, 4),
      Color = (i % 2 == 0) and Color3.fromRGB(188, 132, 72) or Color3.fromRGB(105, 76, 54),
      Material = Enum.Material.WoodPlanks,
      Tags = { "MovingPlatform", "Beacon" },
      Attributes = {
        Amplitude = 4,
        Speed = scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.45, 0.7, 1.3),
        Axis = Vector3.new(0, 0, 1),
        CarryPlayers = true,
        Phase = i * 0.9,
      },
    })
    addSparkles(cargo, Color3.fromRGB(255, 220, 130), 3)
  end
  addSign(model, ctx.origin * CFrame.new(span * 0.42, 7, -8), "Mind the shifting cargo")
  addSign(model, ctx.origin * CFrame.new(8, 6, -8), "Barge crossing")
  return model, endCFrame
end

function StageTemplates.TrainTunnelDash(ctx)
  local model, endCFrame = StageTemplates.TrainTunnel(ctx)
  addSign(model, ctx.origin * CFrame.new(10, 7, 7), "Train tunnel dash")
  return model, endCFrame
end

function StageTemplates.WildWoodGusts(ctx)
  local model, endCFrame = StageTemplates.WildWoods(ctx)
  addSign(model, ctx.origin * CFrame.new(8, 7, -7), "Wild Wood gusts")
  return model, endCFrame
end

function StageTemplates.BadgerLanternPath(ctx)
  local model = Build.model("Stage_BadgerLanternPath", ctx.parent)
  local length = WorldGenConfig.StageLengthMax

  basePlatform(model, ctx.origin, Color3.fromRGB(92, 72, 56), Vector3.new(12, 1, WorldGenConfig.PathWidth - 4))
  for i = 1, 6 do
    local z = (i % 2 == 0) and 5 or -5
    local log = Build.part({
      Name = "BadgerLogBridge",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 7) * i, 0.9 + i * 0.18, z),
      Size = Vector3.new(10, 1.2, 5),
      Color = Color3.fromRGB(105, 75, 45),
      Material = Enum.Material.Wood,
      Tags = { "Beacon" },
    })
    if i % 3 == 0 then
      Build.tag(log, { "MovingPlatform" })
      log:SetAttribute("Amplitude", 3)
      log:SetAttribute("Speed", scaleSpeed(ctx, ObstacleConfig.MovingPlatformSpeed * 0.35, 0.8, 1.4))
      log:SetAttribute("Axis", Vector3.new(0, 0, 1))
      log:SetAttribute("CarryPlayers", true)
    end
  end

  for i = 0, 6 do
    local lantern = Build.part({
      Name = "BadgerLantern",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 6) * i, 6.5, (i % 2 == 0) and -8 or 8),
      Size = Vector3.new(1.4, 2, 1.4),
      Color = Color3.fromRGB(255, 214, 120),
      Material = Enum.Material.Neon,
      Tags = { "Beacon" },
    })
    lantern.CanCollide = false
    local glow = Instance.new("PointLight")
    glow.Range = 20
    glow.Brightness = 4
    glow.Color = Color3.fromRGB(255, 220, 150)
    glow.Parent = lantern
  end

  basePlatform(
    model,
    ctx.origin * CFrame.new(length, 0.6, 0),
    Color3.fromRGB(92, 72, 56),
    Vector3.new(12, 1, WorldGenConfig.PathWidth - 4)
  )
  addSign(model, ctx.origin * CFrame.new(8, 6, 0), "Follow Badger's lights")
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

function StageTemplates.MotorcarMadness(ctx)
  local model, endCFrame = StageTemplates.MotorMadness(ctx)
  addSign(model, ctx.origin * CFrame.new(10, 6, 7), "Motorcar madness")
  return model, endCFrame
end

function StageTemplates.RoadsideConeSprint(ctx)
  local model = Build.model("Stage_RoadsideConeSprint", ctx.parent)
  local length = WorldGenConfig.StageLengthMin + 18

  local road = basePlatform(
    model,
    ctx.origin * CFrame.new(length * 0.5, 0, 0),
    Color3.fromRGB(55, 55, 62),
    Vector3.new(length, 1, WorldGenConfig.PathWidth)
  )
  road.Material = Enum.Material.Asphalt
  road:SetAttribute("Speed", scaleSpeed(ctx, ObstacleConfig.ConveyorSpeed * 1.3, 0.7, 1.5))
  Build.tag(road, { "Conveyor" })

  for i = 1, 7 do
    local cone = Build.part({
      Name = "StoryCone",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 8) * i, 1.2, (i % 2 == 0) and 5 or -5),
      Size = Vector3.new(2, 3, 2),
      Color = Color3.fromRGB(255, 140, 45),
      Material = Enum.Material.Neon,
      Tags = { "Rotator", "KillBrick" },
      Attributes = { RotSpeed = scaleSpeed(ctx, ObstacleConfig.RotatorSpeed, 0.8, 1.7) },
    })
    cone.Shape = Enum.PartType.Cylinder
    cone.CanCollide = false
  end

  local sidewalk = basePlatform(
    model,
    ctx.origin * CFrame.new(length * 0.5, 0.5, WorldGenConfig.PathWidth * 0.55),
    Color3.fromRGB(230, 230, 220),
    Vector3.new(length, 0.5, 4)
  )
  sidewalk.Material = Enum.Material.SmoothPlastic

  addSign(model, ctx.origin * CFrame.new(8, 6, -7), "Cone sprint!")
  addPathLights(model, ctx.origin, length, Color3.fromRGB(255, 210, 120), -WorldGenConfig.PathWidth * 0.45)
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

function StageTemplates.HomecomingRingRun(ctx)
  local model = Build.model("Stage_HomecomingRingRun", ctx.parent)
  local length = WorldGenConfig.StageLengthMax
  local steps = 9

  for i = 0, steps do
    local pct = i / steps
    local z = math.sin(pct * math.pi * 2) * 7
    local y = math.sin(pct * math.pi) * 4
    local platform = basePlatform(
      model,
      ctx.origin * CFrame.new(length * pct, y, z),
      Color3.fromRGB(120, 235, 210):Lerp(Color3.fromRGB(255, 210, 120), pct),
      Vector3.new(9, 1, 9)
    )
    platform.Material = Enum.Material.Neon
    addSparkles(platform, Color3.fromRGB(255, 245, 180), 8)
  end

  for i = 1, 4 do
    local ring = Build.part({
      Name = "HomecomingRing",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 5) * i, 5.5, 0),
      Size = Vector3.new(1.2, 10, WorldGenConfig.PathWidth - 4),
      Color = Color3.fromRGB(255, 230, 120),
      Material = Enum.Material.Neon,
      Tags = { "Beacon" },
    })
    ring.CanCollide = false
  end

  addSign(model, ctx.origin * CFrame.new(8, 7, -8), "Homecoming ring run")
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

function StageTemplates.ToadHallFireworks(ctx)
  local model = Build.model("Stage_ToadHallFireworks", ctx.parent)
  local length = WorldGenConfig.StageLengthMin + 24

  local carpet = basePlatform(
    model,
    ctx.origin * CFrame.new(length * 0.5, 0, 0),
    Color3.fromRGB(220, 55, 80),
    Vector3.new(length, 1, 10)
  )
  carpet.Material = Enum.Material.Fabric

  for i = 0, 5 do
    local star = Build.part({
      Name = "FinaleStarStep",
      Parent = model,
      CFrame = ctx.origin * CFrame.new((length / 5) * i, 1.2, (i % 2 == 0) and -5 or 5),
      Size = Vector3.new(8, 1, 8),
      Color = (i % 2 == 0) and Color3.fromRGB(255, 225, 110) or Color3.fromRGB(120, 240, 255),
      Material = Enum.Material.Neon,
      Tags = { "Beacon" },
    })
    addSparkles(star, Color3.fromRGB(255, 255, 200), 14)
  end

  addArch(model, ctx.origin * CFrame.new(length * 0.82, 0, 0), "Toad Hall Party", Color3.fromRGB(120, 80, 50))

  -- The finish line is a small theatrical set rather than a bare checkpoint:
  -- towers, bunting, and bells make the destination readable from the approach.
  for _, side in ipairs({ -1, 1 }) do
    local tower = Build.part({
      Name = "FinaleBellTower",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(length * 0.82, 5, side * 8),
      Size = Vector3.new(3, 10, 3),
      Color = Color3.fromRGB(184, 164, 128),
      Material = Enum.Material.Slate,
    })
    tower.CanCollide = false
    local bell = Build.part({
      Name = "FinaleBell",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(length * 0.82, 11, side * 8),
      Size = Vector3.new(4, 2, 4),
      Color = Color3.fromRGB(218, 166, 72),
      Material = Enum.Material.Metal,
    })
    bell.Shape = Enum.PartType.Ball
    bell.CanCollide = false
  end

  for i = 1, 7 do
    local bunting = Build.part({
      Name = "FinaleBunting",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(length * (0.58 + i * 0.05), 10 - math.abs(4 - i) * 0.45, 0),
      Size = Vector3.new(3, 0.35, 5),
      Color = (i % 2 == 0) and Color3.fromRGB(120, 240, 255) or Color3.fromRGB(255, 225, 110),
      Material = Enum.Material.Fabric,
    })
    bunting.CanCollide = false
  end

  for i = 1, 5 do
    local firework = Build.part({
      Name = "FinaleFirework",
      Parent = model,
      CFrame = ctx.origin * CFrame.new(length * (0.2 + i * 0.12), 18 + i, (i % 2 == 0) and 8 or -8),
      Size = Vector3.new(1, 1, 1),
      Color = Color3.fromRGB(255, 255, 255),
      Material = Enum.Material.Neon,
    })
    firework.CanCollide = false
    local burst = Instance.new("ParticleEmitter")
    burst.Texture = AssetRegistry.getApprovedId("finale_firework")
    burst.Rate = 26
    burst.Lifetime = NumberRange.new(0.8, 1.4)
    burst.Speed = NumberRange.new(18, 28)
    burst.SpreadAngle = Vector2.new(360, 360)
    burst.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(120, 240, 255))
    burst.Parent = firework
  end

  addSign(model, ctx.origin * CFrame.new(10, 7, -8), "Final dash to Toad Hall!")
  return model, ctx.origin * CFrame.new(length + 8, 0, 0)
end

return StageTemplates
