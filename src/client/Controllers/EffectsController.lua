local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local AssetRegistry = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AssetRegistry"))
local SoundGroups = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("SoundGroups"))
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))

local EffectsController = {}
EffectsController.__index = EffectsController

function EffectsController.new()
  local self = setmetatable({}, EffectsController)
  self.player = Players.LocalPlayer
  local events = ReplicatedStorage:WaitForChild("SharedEvents")
  self.progressEvent = events:WaitForChild(RemoteContracts.Progress.name)
  self.finaleEvent = events:WaitForChild(RemoteContracts.Finale.name)
  self:bind()
  return self
end

function EffectsController:bind()
  self.progressEvent.OnClientEvent:Connect(function(payload)
    if not payload.initialized then
      self:checkpointPulse()
    end
  end)
  self.finaleEvent.OnClientEvent:Connect(function()
    self:finale()
  end)
end

function EffectsController:checkpointPulse()
  if
    self.player:GetAttribute("Accessibility_reduceFlashes")
    or self.player:GetAttribute("Accessibility_reducedMotion")
  then
    return
  end
  local gui = Instance.new("Frame")
  gui.Name = "CheckpointPulse"
  gui.BackgroundColor3 = Color3.fromRGB(218, 166, 72)
  gui.Size = UDim2.fromScale(0.18, 0.012)
  gui.Position = UDim2.fromScale(0.41, 0.07)
  gui.BackgroundTransparency = 0.15
  gui.BorderSizePixel = 0
  gui.Parent = self.player:WaitForChild("PlayerGui")
  TweenService:Create(gui, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(0.3, 0.012),
  }):Play()
  Debris:AddItem(gui, 0.5)
end

function EffectsController:finale()
  local reducedMotion = self.player:GetAttribute("Accessibility_reducedMotion")
  local reduceFlashes = self.player:GetAttribute("Accessibility_reduceFlashes")
  local char = self.player.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  if not reduceFlashes then
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting
    TweenService:Create(
      blur,
      TweenInfo.new(reducedMotion and 0.1 or 1.6, Enum.EasingStyle.Quad),
      { Size = reducedMotion and 0 or 10 }
    ):Play()
    Debris:AddItem(blur, 2.5)
  end

  if not reducedMotion and not reduceFlashes then
    local spot = Instance.new("SpotLight")
    spot.Brightness = 4
    spot.Angle = 90
    spot.Range = 40
    if root then
      spot.Parent = root
      TweenService:Create(spot, TweenInfo.new(2, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
      Debris:AddItem(spot, 3)
    else
      spot:Destroy()
    end
  end

  if not reduceFlashes then
    local color = Instance.new("ColorCorrectionEffect")
    color.TintColor = Color3.fromRGB(255, 240, 210)
    color.Parent = Lighting
    TweenService:Create(
      color,
      TweenInfo.new(reducedMotion and 0.1 or 0.8, Enum.EasingStyle.Quad),
      { Brightness = 0.25, Saturation = 0.3 }
    ):Play()
    Debris:AddItem(color, 2)
  end

  -- Fireworks at the player
  local fireworkTexture = AssetRegistry.getApprovedId("finale_firework")
  local finaleChime = AssetRegistry.getApprovedId("finale_chime")
  if root and not reducedMotion and not reduceFlashes and fireworkTexture ~= "" then
    for _ = 1, 3 do
      local boom = Instance.new("ParticleEmitter")
      boom.Texture = fireworkTexture
      boom.Lifetime = NumberRange.new(1, 1.6)
      boom.Speed = NumberRange.new(32, 38)
      boom.Rate = self.player:GetAttribute("Accessibility_lowParticles") and 40 or 200
      boom.SpreadAngle = Vector2.new(360, 360)
      boom.Parent = root
      boom:Emit(self.player:GetAttribute("Accessibility_lowParticles") and 40 or 200)
      Debris:AddItem(boom, 2)
    end
    if finaleChime ~= "" then
      local s = Instance.new("Sound")
      s.SoundId = finaleChime
      s.Volume = 1
      s.SoundGroup = SoundGroups.ensure("SFX", 0.8)
      s.Parent = root
      s:Play()
      Debris:AddItem(s, 3)
    end
  end
end

return EffectsController
