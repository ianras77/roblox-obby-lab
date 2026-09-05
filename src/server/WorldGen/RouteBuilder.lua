local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Build = require(ReplicatedStorage.Util.Build)
local RoutePlan = require(ReplicatedStorage.Util.RoutePlan)
local RouteBuilder = {}

function RouteBuilder.connect(parent, a, b, name)
  local delta = b.Position - a.Position
  if delta.Magnitude < 0.01 then
    return nil
  end
  -- Roblox lookAt aims -Z; rotate so the long local X axis follows the route.
  return Build.part({
    Name = name or "ScenicConnector",
    Parent = parent,
    Size = Vector3.new(delta.Magnitude + 2, 1, 14),
    CFrame = CFrame.lookAt((a.Position + b.Position) / 2, b.Position) * CFrame.Angles(0, math.pi / 2, 0),
    Color = Color3.fromRGB(170, 196, 135),
    Material = Enum.Material.WoodPlanks,
    Attributes = { RequiredSupport = true },
  })
end

function RouteBuilder.stage(ctx, definition)
  local model = Build.model(definition.canonicalName, ctx.parent)
  local nodes = RoutePlan.stage(definition)
  for index, node in ipairs(nodes) do
    local landing = Build.part({
      Name = "MainPath_" .. index,
      Parent = model,
      Size = Vector3.new(node.width, 1, node.depth),
      CFrame = ctx.origin * CFrame.new(node.x, node.y, node.z),
      Color = ctx.color,
      Attributes = { RequiredSupport = true, RouteNode = index },
    })
    if definition.index == 6 and index >= 3 and index <= 5 then
      Build.tag(landing, { "Conveyor" })
      landing:SetAttribute("Direction", "Forward")
      landing:SetAttribute("Speed", definition.movement.speed)
    elseif definition.index == 7 and index >= 2 and index <= 5 then
      landing.Color = Color3.fromRGB(150, 95, 45)
      landing.Material = Enum.Material.WoodPlanks
    elseif definition.index == 14 then
      landing.Material = Enum.Material.Slate
    end
    local mark = Build.part({
      Name = "ForwardBreadcrumb",
      Parent = model,
      Size = Vector3.new(3, 0.1, 2),
      CFrame = ctx.origin * CFrame.new(node.x, 0.56, 0),
      Color = Color3.fromRGB(250, 238, 177),
      CanCollide = false,
      CanTouch = false,
    })
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.Parent = mark
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = ">>"
    text.TextScaled = true
    text.Parent = gui
  end
  -- A broad catch deck turns missed jumps into a small setback, never death.
  Build.part({
    Name = "CatchFloor",
    Parent = model,
    Size = Vector3.new(112, 1, 60),
    CFrame = ctx.origin * CFrame.new(48, -4, 8),
    Color = Color3.fromRGB(125, 170, 125),
  })
  RouteBuilder.connect(model, ctx.origin * CFrame.new(16, -4, 0), ctx.origin * CFrame.new(32, 0, 0), "CatchRamp")
  -- The challenge detour is explicit, visible and connected at both ends.
  Build.part({
    Name = "OptionalLane",
    Parent = model,
    Size = Vector3.new(72, 1, 12),
    CFrame = ctx.origin * CFrame.new(48, 0, 22),
    Color = Color3.fromRGB(175, 140, 200),
  })
  RouteBuilder.connect(model, ctx.origin * CFrame.new(16, 0, 0), ctx.origin * CFrame.new(16, 0, 22), "OptionalEntrance")
  RouteBuilder.connect(model, ctx.origin * CFrame.new(80, 0, 22), ctx.origin * CFrame.new(80, 0, 0), "OptionalReturn")
  local index = definition.index
  local tags, size, offset, attributes = {}, Vector3.new(10, 1, 10), Vector3.new(48, 1, 22), {}
  if index == 2 then
    tags = { "BouncePad" }
    attributes.Power = 34
  elseif index == 3 or index == 11 or index == 12 then
    tags = { "MovingPlatform" }
    attributes.PeriodSeconds = definition.movement.periodSeconds
    attributes.Amplitude = 4
    attributes.Axis = "X"
  elseif index == 4 or index == 7 or index == 16 then
    tags = { "Rotator" }
    size = Vector3.new(8, 1, 2)
    attributes.RotSpeed = 0.5
  elseif index == 5 or index == 8 or index == 9 then
    tags = { "Laser", "KillBrick" }
    size = Vector3.new(1, 5, 10)
    offset = Vector3.new(48, 3, 22)
    attributes.Cycle = 6
    attributes.WarningSeconds = definition.warningSeconds
    attributes.Phase = 0
  elseif index == 6 or index == 15 then
    tags = { "Conveyor" }
    attributes.Speed = definition.movement.speed
    attributes.Direction = "Forward"
  elseif index == 13 then
    tags = { "WindZone" }
    size = Vector3.new(30, 8, 10)
    attributes.Force = 6
  elseif index == 17 then
    tags = { "BouncePad" }
    attributes.Power = 38
  end
  if #tags > 0 then
    local laser = index == 5 or index == 8 or index == 9
    Build.part({
      Name = "Lesson_" .. definition.canonicalName,
      Parent = model,
      Size = size,
      CFrame = ctx.origin * CFrame.new(offset),
      Color = Color3.fromRGB(245, 180, 85),
      CanCollide = not laser and index ~= 13,
      CanTouch = not laser,
      Transparency = index == 13 and 0.7 or 0,
      Tags = tags,
      Attributes = attributes,
    })
  end
  if index == 2 then
    Build.part({
      Name = "WobblyRoot",
      Parent = model,
      Size = Vector3.new(10, 1, 10),
      CFrame = ctx.origin * CFrame.new(70, 1, 22),
      Color = Color3.fromRGB(140, 95, 55),
      Tags = { "FallingPlatform" },
      Attributes = { DropDelay = definition.fallingDelay },
    })
  end
  if index == 10 then
    Build.cart(ctx.origin * CFrame.new(24, 2, 22), model, 48)
  end
  for _, z in ipairs({ -9, 31 }) do
    Build.part({
      Name = "CatchRail",
      Parent = model,
      Size = Vector3.new(108, 3, 1),
      CFrame = ctx.origin * CFrame.new(48, 0, z),
      Color = Color3.fromRGB(110, 80, 50),
      Material = Enum.Material.Wood,
    })
  end
  -- Chapter silhouettes reuse procedural wood/stone styling without moving collision scenery.
  for _, x in ipairs({ 8, 88 }) do
    local lantern = Build.part({
      Name = "ChapterLantern",
      Parent = model,
      Size = Vector3.new(2, 6, 2),
      CFrame = ctx.origin * CFrame.new(x, 3, -12),
      Color = ctx.color,
    })
    local sign = Instance.new("BillboardGui")
    sign.Size = UDim2.fromOffset(240, 80)
    sign.Adornee = lantern
    sign.StudsOffset = Vector3.new(0, 5, 0)
    sign.Parent = lantern
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.TextWrapped = true
    label.TextScaled = true
    label.Text = x == 8 and definition.teachingGoal or "Golden detour optional • Follow >> home"
    label.Parent = sign
  end
  local function scenery(name, x, y, z, sx, sy, sz, color)
    return Build.part({
      Name = name,
      Parent = model,
      Size = Vector3.new(sx, sy, sz),
      CFrame = ctx.origin * CFrame.new(x, y, z),
      Color = color,
      Material = Enum.Material.Wood,
      CanCollide = false,
      CanTouch = false,
      CanQuery = false,
      CastShadow = false,
    })
  end
  local brown, green, stone = Color3.fromRGB(120, 76, 42), Color3.fromRGB(88, 145, 85), Color3.fromRGB(170, 165, 148)
  if index <= 3 or index == 11 then
    scenery("RiverRibbon", 48, -5, -22, 112, 0.5, 18, Color3.fromRGB(85, 155, 205))
    for x = 12, 84, 24 do
      scenery("Reed", x, 2, -17, 1, 5, 1, green)
      scenery("RattyBoat", x, 0, 37, 12, 2, 5, brown)
    end
  elseif index == 4 or index == 18 then
    for _, z in ipairs({ -14, 37 }) do
      scenery("HallTower", 86, 10, z, 8, 22, 8, stone)
      scenery("TowerRoof", 86, 22, z, 10, 2, 10, brown)
    end
    scenery("WelcomeHomeArch", 86, 22, 11, 8, 3, 60, stone)
  elseif index == 5 then
    for x = 16, 80, 16 do
      scenery("Bookshelf", x, 5, -15, 10, 12, 3, brown)
      for book = 1, 5 do
        scenery("GiantBook", x - 5 + book * 1.7, 6, -17, 1, 7, 2, Color3.fromHSV(book / 6, 0.5, 0.8))
      end
    end
  elseif index == 6 or index == 10 then
    scenery("LaundryCaravan", 48, 6, 39, 24, 12, 10, Color3.fromRGB(230, 215, 180))
    scenery("CaravanRoof", 48, 13, 39, 28, 2, 12, brown)
  elseif index == 7 or index == 8 then
    scenery("JudgesBench", 48, 5, -17, 36, 10, 8, brown)
    scenery("ComicGavelHead", 48, 12, -17, 14, 5, 6, brown)
    scenery("ComicGavelHandle", 48, 17, -17, 2, 10, 2, brown)
  elseif index == 9 then
    for x = 8, 88, 8 do
      scenery("JailBars", x, 6, -15, 1, 12, 1, stone)
    end
  elseif index == 12 then
    scenery("TunnelRoof", 48, 15, 24, 100, 3, 14, stone)
    for _, x in ipairs({ 4, 92 }) do
      scenery("TunnelPillar", x, 7, 32, 4, 14, 4, stone)
    end
    scenery("Rail", 48, 0, 22, 104, 0.2, 2, brown)
  elseif index == 13 or index == 14 then
    for x = 8, 88, 20 do
      scenery("WildWoodTrunk", x, 6, -17, 4, 12, 4, brown)
      scenery("WildWoodCanopy", x, 14, -17, 16, 10, 12, green)
    end
  elseif index == 15 or index == 16 then
    for x = 16, 80, 16 do
      scenery("RoadCone", x, 2, 30, 3, 4, 3, Color3.fromRGB(255, 145, 60))
      scenery("RoadStripe", x, 0.6, 22, 6, 0.1, 1, Color3.fromRGB(250, 245, 200))
    end
  elseif index == 17 then
    for x = 16, 80, 16 do
      scenery("HomecomingBanner", x, 9, -12, 10, 6, 0.5, Color3.fromRGB(230, 155, 185))
      scenery("BannerPole", x, 5, -12, 1, 10, 1, brown)
    end
  end
  return model, ctx.origin * CFrame.new(definition.path.length, 0, 0)
end
return RouteBuilder
