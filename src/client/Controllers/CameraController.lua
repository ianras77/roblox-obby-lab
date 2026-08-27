--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
  local self = setmetatable({}, CameraController)
  self.player = Players.LocalPlayer
  local events = ReplicatedStorage:WaitForChild("SharedEvents")
  self.finaleEvent = events:WaitForChild(RemoteContracts.Finale.name)
  self.finaleEvent.OnClientEvent:Connect(function()
    self:celebrate()
  end)
  return self
end

function CameraController:celebrate()
  if self.player:GetAttribute("Accessibility_reducedMotion") then
    return
  end
  local character = self.player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    return
  end
  local baseline = humanoid.CameraOffset
  local lift = TweenService:Create(humanoid, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
    CameraOffset = baseline + Vector3.new(0, 0.35, 0),
  })
  local settle = TweenService:Create(humanoid, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {
    CameraOffset = baseline,
  })
  lift.Completed:Connect(function(state)
    if state == Enum.PlaybackState.Completed and humanoid.Parent then
      settle:Play()
    end
  end)
  lift:Play()
end

return CameraController
