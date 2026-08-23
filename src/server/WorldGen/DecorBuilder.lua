local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local DecorBuilder = {}

local function ensureSound(name, soundId)
  local sound = SoundService:FindFirstChild(name) or Instance.new("Sound")
  sound.Name = name
  sound.SoundId = soundId or ""
  sound.Looped = true
  sound.Volume = 0.4
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

  ensureSound("ZoneAmbience", zoneConfig.AmbientSoundId)
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

  -- Floating confetti emitter high above the zone for motion and brightness
  local confetti = Instance.new("Part")
  confetti.Name = "SkyConfetti"
  confetti.Anchored = true
  confetti.CanCollide = false
  confetti.Transparency = 1
  confetti.Size = Vector3.new(4, 1, 4)
  confetti.CFrame = CFrame.new(0, 90, 0)
  confetti.Parent = zoneModel

  local emitter = Instance.new("ParticleEmitter")
  emitter.Texture = "rbxassetid://241594419"
  emitter.Rate = 80
  emitter.Lifetime = NumberRange.new(4, 7)
  emitter.Speed = NumberRange.new(6, 10)
  emitter.SpreadAngle = Vector2.new(360, 360)
  emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.6) })
  emitter.Color = ColorSequence.new(zoneConfig.ThemeColor, Color3.new(1, 1, 1))
  emitter.Parent = confetti

  -- Gentle fireflies near ground for added sparkle
  for _ = 1, 4 do
    local firefly = Instance.new("ParticleEmitter")
    firefly.Texture = "rbxassetid://260430117"
    firefly.Rate = 6
    firefly.Lifetime = NumberRange.new(2, 3.2)
    firefly.Speed = NumberRange.new(0.5, 1.5)
    firefly.SpreadAngle = Vector2.new(180, 180)
    firefly.Size = NumberSequence.new(0.35)
    firefly.Color = ColorSequence.new(zoneConfig.ThemeColor:Lerp(Color3.new(1, 1, 1), 0.4))
    firefly.Parent = zoneModel
  end
end

return DecorBuilder
