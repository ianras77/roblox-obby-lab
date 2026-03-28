local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Build = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Build"))
local ObstacleConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ObstacleConfig"))
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))

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
    sparkle.Texture = "rbxassetid://260430117"
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
    addBillboard(model, balloon, "Toad's Wild Welcome", Color3.fromRGB(255, 230, 200))
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
    puff.Texture = "rbxassetid://241594419"
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
  decal.Texture = "rbxassetid://148274626" -- kid-safe frog decal
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
  bubbles.Texture = "rbxassetid://241594419"
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
    local barrel = Build.part({
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

  local tracks = Build.part({
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

  return model, ctx.origin * CFrame.new(length + 14, 0, 0)
end

-- Stage: SeesawGate (co-op pads open gate)
function StageTemplates.SeesawGate(ctx)
  local model = Build.model("Stage_SeesawGate", ctx.parent)
  local length = WorldGenConfig.StageLengthMin
  basePlatform(model, ctx.origin, ctx.color, Vector3.new(length, 1, WorldGenConfig.PathWidth))

  local gateId = string.format("Gate_%03d", ctx.stageIndex or ctx.random:NextInteger(1000, 9999))

  local gate = Build.part({
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
    sparks.Texture = "rbxassetid://260430117"
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
      Anchored = false,
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
  leaves.Texture = "rbxassetid://484084159"
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
  emitter.Texture = "rbxassetid://258128463"
  emitter.Rate = 24
  emitter.Lifetime = NumberRange.new(1, 1.5)
  emitter.Speed = NumberRange.new(25, 35)
  emitter.Parent = model

  local confetti = Instance.new("ParticleEmitter")
  confetti.Texture = "rbxassetid://12824333"
  confetti.Rate = 40
  confetti.Lifetime = NumberRange.new(1, 1.2)
  confetti.Speed = NumberRange.new(12, 16)
  confetti.Rotation = NumberRange.new(-180, 180)
  confetti.Parent = model
  return model, ctx.origin * CFrame.new(radius * 2 + 20, 0, 0)
end

return StageTemplates
