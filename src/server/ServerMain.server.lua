local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local AssetRegistry = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AssetRegistry"))
local SoundGroups = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("SoundGroups"))
local ObbyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("ObbyService"))

SoundGroups.ensure("Music", 0.45)
SoundGroups.ensure("Ambience", 0.35)
SoundGroups.ensure("SFX", 0.8)
SoundGroups.ensure("UI", 0.8)

local function playFirstApprovedMusic(assets)
  for _, asset in ipairs(assets) do
    if not asset.verified or not asset.approvedForRelease then
      continue
    end
    local sound = Instance.new("Sound")
    sound.Name = "ObbyMusic"
    sound.SoundId = asset.id
    sound.Looped = true
    sound.Volume = 0.45
    sound.SoundGroup = SoundGroups.ensure("Music", 0.45)
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
  warn("[Music] No approved registry asset is available; running without music.")
  return nil
end

playFirstApprovedMusic(AssetRegistry.music)

ObbyService.new()
