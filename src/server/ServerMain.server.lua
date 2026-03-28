local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local ObbyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("ObbyService"))

local function playFirstWorkingMusic(ids)
  for _, id in ipairs(ids) do
    local sound = Instance.new("Sound")
    sound.Name = "ObbyMusic"
    sound.SoundId = id
    sound.Looped = true
    sound.Volume = 0.45
    sound.Parent = SoundService
    local ok = pcall(function()
      ContentProvider:PreloadAsync({ sound })
    end)
    if ok then
      sound:Play()
      return sound
    end
    sound:Destroy()
  end
  warn("[Music] All candidate MusicIds failed to preload; no music will play.")
  return nil
end

playFirstWorkingMusic(GameConfig.MusicIds)

ObbyService.new()
