-- This file holds small builders for obstacle pieces that StageTemplates can reuse later.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Build = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Build"))

local ObstacleTemplates = {}

function ObstacleTemplates.killBrick(parent, cframe, size)
  return Build.part({
    Name = "KillBrick",
    Parent = parent,
    CFrame = cframe,
    Size = size or Vector3.new(8, 1, 8),
    Color = Color3.fromRGB(255, 60, 60),
    Material = Enum.Material.Neon,
    Tags = { "KillBrick" },
  })
end

function ObstacleTemplates.movingPlatform(parent, cframe, amplitude, speed, props)
  local part = Build.part({
    Name = "MovingPlatform",
    Parent = parent,
    CFrame = cframe,
    Size = Vector3.new(10, 1, 10),
    Color = Color3.fromRGB(255, 200, 80),
    Tags = { "MovingPlatform" },
    Attributes = {
      Amplitude = amplitude,
      PeriodSeconds = (props and props.PeriodSeconds) or 4,
      Axis = props and props.Axis,
      Phase = props and props.Phase,
      CarryPlayers = props and props.CarryPlayers,
    },
  })
  return part
end

return ObstacleTemplates
