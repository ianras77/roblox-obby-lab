--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ZoneConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local EnvironmentController = {}
EnvironmentController.__index = EnvironmentController

function EnvironmentController.new()
  local self = setmetatable({}, EnvironmentController)
  self.player = Players.LocalPlayer
  self.event = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(GameConfig.ProgressRemote)
  self.stateFunction = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild("GetObbyState")
  self.atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
  self.atmosphere.Parent = Lighting
  self.colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    or Instance.new("ColorCorrectionEffect")
  self.colorCorrection.Parent = Lighting
  self:bind()
  self:syncInitialState()
  return self
end

function EnvironmentController:syncInitialState()
  local ok, payload = pcall(function()
    return self.stateFunction:InvokeServer()
  end)
  if ok and payload then
    self:transition(payload.stage or 0)
  end
end

function EnvironmentController:bind()
  self.event.OnClientEvent:Connect(function(payload)
    self:transition(payload.stage or 0)
  end)
end

function EnvironmentController:transition(stage: number)
  local zoneIndex = math.clamp(math.ceil(math.max(stage, 1) / GameConfig.StagesPerZone), 1, #ZoneConfig)
  local config = ZoneConfig[zoneIndex]
  local duration = self.player:GetAttribute("Accessibility_reducedMotion") and 0.05 or 1.25
  local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
  TweenService:Create(Lighting, info, {
    Ambient = config.Ambient,
    OutdoorAmbient = config.Ambient,
    FogColor = config.FogColor,
    FogEnd = config.FogEnd or 340,
    ClockTime = config.ClockTime or 14,
  }):Play()
  TweenService:Create(self.atmosphere, info, {
    Color = config.SkyColor,
    Decay = config.FogColor,
  }):Play()
  TweenService:Create(self.colorCorrection, info, {
    TintColor = config.ThemeColor,
  }):Play()
end

return EnvironmentController
