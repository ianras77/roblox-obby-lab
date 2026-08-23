local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AssetRegistry"))
local Build = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Build"))

local DecorBuilder = {}

local function landmarkPart(parent, name, size, position, color, material)
  local part = Build.part({
    Name = name,
    Parent = parent,
    Size = size,
    CFrame = CFrame.new(position),
    Color = color,
    Material = material or Enum.Material.Wood,
  })
  part.CanCollide = false
  part.CanTouch = false
  part.CanQuery = false
  return part
end

local function addLandmark(zoneModel, zoneConfig, center, size)
  local landmark = Build.model("DistantLandmark", zoneModel)
  local rearZ = center.Z + size.Z * 0.5 + 32
  local groundY = center.Y - size.Y * 0.5
  if zoneConfig.Name == "Riverbank and Toad Hall" then
    local stone = Color3.fromRGB(184, 164, 128)
    local roof = Color3.fromRGB(94, 61, 45)
    landmarkPart(
      landmark,
      "HallBody",
      Vector3.new(34, 18, 5),
      Vector3.new(center.X, groundY + 9, rearZ),
      stone,
      Enum.Material.Slate
    )
    landmarkPart(landmark, "HallRoof", Vector3.new(40, 3, 8), Vector3.new(center.X, groundY + 19, rearZ), roof)
    for offset = -12, 12, 12 do
      landmarkPart(
        landmark,
        "WarmWindow",
        Vector3.new(4, 5, 0.4),
        Vector3.new(center.X + offset, groundY + 10, rearZ - 2.7),
        Color3.fromRGB(255, 215, 112),
        Enum.Material.Neon
      )
    end
    landmarkPart(
      landmark,
      "HallTower",
      Vector3.new(8, 25, 6),
      Vector3.new(center.X + 23, groundY + 12.5, rearZ),
      stone,
      Enum.Material.Slate
    )
  elseif zoneConfig.Name == "Trouble and Escape" then
    local iron = Color3.fromRGB(55, 62, 70)
    local brass = Color3.fromRGB(204, 151, 64)
    landmarkPart(
      landmark,
      "RailwayShed",
      Vector3.new(38, 13, 6),
      Vector3.new(center.X, groundY + 6.5, rearZ),
      Color3.fromRGB(128, 75, 48),
      Enum.Material.Wood
    )
    landmarkPart(
      landmark,
      "ShedRoof",
      Vector3.new(44, 2, 8),
      Vector3.new(center.X, groundY + 14, rearZ),
      iron,
      Enum.Material.Metal
    )
    landmarkPart(
      landmark,
      "SignalPost",
      Vector3.new(1.5, 18, 1.5),
      Vector3.new(center.X - 25, groundY + 9, rearZ),
      iron,
      Enum.Material.Metal
    )
    landmarkPart(
      landmark,
      "SignalLamp",
      Vector3.new(4, 4, 2),
      Vector3.new(center.X - 25, groundY + 18, rearZ),
      brass,
      Enum.Material.Neon
    )
  else
    local trunk = Color3.fromRGB(73, 54, 42)
    local lantern = Color3.fromRGB(176, 223, 255)
    for offset = -22, 22, 22 do
      landmarkPart(
        landmark,
        "LanternTreeTrunk",
        Vector3.new(3, 18, 3),
        Vector3.new(center.X + offset, groundY + 9, rearZ),
        trunk,
        Enum.Material.Wood
      )
      landmarkPart(
        landmark,
        "LanternGlow",
        Vector3.new(3, 3, 3),
        Vector3.new(center.X + offset, groundY + 19, rearZ),
        lantern,
        Enum.Material.Neon
      )
    end
  end
end

local function ensureSound(name, soundId)
  local sound = SoundService:FindFirstChild(name) or Instance.new("Sound")
  sound.Name = name
  sound.SoundId = soundId or ""
  sound.Looped = true
  sound.Volume = 0.4
  sound.SoundGroup = SoundService:FindFirstChild("Ambience")
  sound.Parent = SoundService
  if soundId and soundId ~= "" then
    sound:Play()
  end
  return sound
end

function DecorBuilder.applyLighting(zoneConfig)
  Lighting.Ambient = zoneConfig.Ambient
  Lighting.OutdoorAmbient = zoneConfig.Ambient
  Lighting.FogColor = zoneConfig.FogColor
  Lighting.FogEnd = zoneConfig.FogEnd or 340
  Lighting.ClockTime = zoneConfig.ClockTime or 14
  Lighting.Brightness = 3.5
  Lighting.ExposureCompensation = 0.45
  Lighting.ColorShift_Bottom = Color3.fromRGB(220, 230, 245)
  Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)

  local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
  atmosphere.Parent = Lighting
  atmosphere.Color = zoneConfig.SkyColor
  atmosphere.Decay = zoneConfig.FogColor
  atmosphere.Density = 0.12
  atmosphere.Glare = 0.28

  local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
  bloom.Parent = Lighting
  bloom.Intensity = 1.7
  bloom.Size = 36

  local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
  cc.Parent = Lighting
  cc.Brightness = 0.25
  cc.Saturation = 0.45
  cc.TintColor = zoneConfig.ThemeColor

  local sun = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
  sun.Parent = Lighting
  sun.Intensity = 0.22
  sun.Spread = 0.95

  ensureSound("ZoneAmbience", AssetRegistry.getApprovedId(zoneConfig.AmbientSoundKey))
end

function DecorBuilder.decorateZone(zoneModel, zoneConfig)
  for _, stageModel in ipairs(zoneModel:GetChildren()) do
    if stageModel:IsA("Model") then
      for _, child in ipairs(stageModel:GetDescendants()) do
        if child:IsA("BasePart") then
          child.Color = zoneConfig.ThemeColor:Lerp(child.Color, 0.25)
        end
      end
    end
  end

  local zoneCFrame, zoneSize = zoneModel:GetBoundingBox()
  addLandmark(zoneModel, zoneConfig, zoneCFrame.Position, zoneSize)

  -- Floating confetti emitter high above the zone for motion and brightness
  local confetti = Instance.new("Part")
  confetti.Name = "SkyConfetti"
  confetti.Anchored = true
  confetti.CanCollide = false
  confetti.Transparency = 1
  confetti.Size = Vector3.new(4, 1, 4)
  confetti.CFrame = CFrame.new(zoneCFrame.Position + Vector3.new(0, zoneSize.Y / 2 + 35, 0))
  confetti.Parent = zoneModel

  local emitter = Instance.new("ParticleEmitter")
  emitter.Texture = AssetRegistry.getApprovedId("soft_particle")
  emitter.Rate = 80
  emitter.Lifetime = NumberRange.new(4, 7)
  emitter.Speed = NumberRange.new(6, 10)
  emitter.SpreadAngle = Vector2.new(360, 360)
  emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.6) })
  emitter.Color = ColorSequence.new(zoneConfig.ThemeColor, Color3.new(1, 1, 1))
  emitter.Parent = confetti

  -- Gentle fireflies near ground for added sparkle
  local fireflyAnchor = Instance.new("Part")
  fireflyAnchor.Name = "FireflyAnchor"
  fireflyAnchor.Anchored = true
  fireflyAnchor.CanCollide = false
  fireflyAnchor.CanTouch = false
  fireflyAnchor.Transparency = 1
  fireflyAnchor.Size = Vector3.new(1, 1, 1)
  fireflyAnchor.Position = zoneCFrame.Position + Vector3.new(0, 4, 0)
  fireflyAnchor.Parent = zoneModel
  for _ = 1, 4 do
    local firefly = Instance.new("ParticleEmitter")
    firefly.Texture = AssetRegistry.getApprovedId("sparkle_particle")
    firefly.Rate = 6
    firefly.Lifetime = NumberRange.new(2, 3.2)
    firefly.Speed = NumberRange.new(0.5, 1.5)
    firefly.SpreadAngle = Vector2.new(180, 180)
    firefly.Size = NumberSequence.new(0.35)
    firefly.Color = ColorSequence.new(zoneConfig.ThemeColor:Lerp(Color3.new(1, 1, 1), 0.4))
    firefly.Parent = fireflyAnchor
  end
end

return DecorBuilder
