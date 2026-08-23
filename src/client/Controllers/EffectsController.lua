local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local EffectsController = {}
EffectsController.__index = EffectsController

function EffectsController.new()
  local self = setmetatable({}, EffectsController)
  self.player = Players.LocalPlayer
  local events = ReplicatedStorage:WaitForChild("SharedEvents")
  self.progressEvent = events:WaitForChild(GameConfig.ProgressRemote)
  self.finaleEvent = events:WaitForChild(GameConfig.FinaleRemote)
  self:bind()
  return self
end

function EffectsController:bind()
  self.progressEvent.OnClientEvent:Connect(function()
    self:flash()
  end)
  self.finaleEvent.OnClientEvent:Connect(function()
    self:finale()
  end)
end

function EffectsController:flash()
  if
    self.player:GetAttribute("Accessibility_reduceFlashes")
    or self.player:GetAttribute("Accessibility_reducedMotion")
  then
    return
  end
  local gui = Instance.new("Frame")
  gui.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  gui.Size = UDim2.fromScale(1, 1)
  gui.BackgroundTransparency = 0.4
  gui.BorderSizePixel = 0
  gui.Parent = self.player:WaitForChild("PlayerGui")
  TweenService
    :Create(gui, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
    :Play()
  game.Debris:AddItem(gui, 0.5)
end

function EffectsController:finale()
  local reducedMotion = self.player:GetAttribute("Accessibility_reducedMotion")
  local blur = Instance.new("BlurEffect")
  blur.Size = 0
  blur.Parent = Lighting
  TweenService:Create(
    blur,
    TweenInfo.new(reducedMotion and 0.1 or 1.6, Enum.EasingStyle.Quad),
    { Size = reducedMotion and 0 or 10 }
  ):Play()
  game.Debris:AddItem(blur, 2.5)

  local spot = Instance.new("SpotLight")
  spot.Brightness = 4
  spot.Angle = 90
  spot.Range = 40
  spot.Parent = workspace.CurrentCamera
  TweenService:Create(spot, TweenInfo.new(2, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
  game.Debris:AddItem(spot, 3)

  local shake = Instance.new("ColorCorrectionEffect")
  shake.TintColor = Color3.fromRGB(255, 240, 210)
  shake.Parent = Lighting
  TweenService:Create(
    shake,
    TweenInfo.new(reducedMotion and 0.1 or 0.8, Enum.EasingStyle.Quad),
    { Brightness = 0.25, Saturation = 0.3 }
  ):Play()
  game.Debris:AddItem(shake, 2)

  -- Fireworks at the player
  local char = self.player.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  if root then
    for _ = 1, 3 do
      local boom = Instance.new("ParticleEmitter")
      boom.Texture = "rbxassetid://258128463"
      boom.Lifetime = NumberRange.new(1, 1.6)
      boom.Speed = NumberRange.new(32, 38)
      boom.Rate = self.player:GetAttribute("Accessibility_lowParticles") and 40 or 200
      boom.SpreadAngle = Vector2.new(360, 360)
      boom.Parent = root
      boom:Emit(200)
      game.Debris:AddItem(boom, 2)
    end
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://138186576"
    s.Volume = 1
    s.Parent = root
    s:Play()
    game.Debris:AddItem(s, 3)
  end
end

return EffectsController
