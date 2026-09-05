local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local VisualController = {}
function VisualController.start()
  local origins = setmetatable({}, { __mode = "k" })
  local elapsed = 0
  RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.1 then
      return
    end
    elapsed = 0
    local player = Players.LocalPlayer
    if player:GetAttribute("Accessibility_reducedMotion") or player:GetAttribute("Accessibility_lowParticles") then
      return
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then
      return
    end
    for _, part in ipairs(CollectionService:GetTagged("VisualBob")) do
      if
        part:IsA("BasePart")
        and part.Anchored
        and not part.CanCollide
        and (part.Position - root.Position).Magnitude < 100
      then
        origins[part] = origins[part] or part.CFrame
        part.CFrame = origins[part] * CFrame.new(0, math.sin(os.clock() * 1.5) * 0.3, 0)
      end
    end
  end)
end
return VisualController
