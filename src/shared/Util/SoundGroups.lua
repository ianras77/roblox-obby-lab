--!strict

local SoundService = game:GetService("SoundService")

local SoundGroups = {}

function SoundGroups.ensure(name: string, volume: number): SoundGroup
  local existing = SoundService:FindFirstChild(name)
  if existing and existing:IsA("SoundGroup") then
    existing.Volume = volume
    return existing
  end
  if existing then
    error("SoundService contains a non-SoundGroup named " .. name)
  end
  local group = Instance.new("SoundGroup")
  group.Name = name
  group.Volume = volume
  group.Parent = SoundService
  return group
end

return SoundGroups
