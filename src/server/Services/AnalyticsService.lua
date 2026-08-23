--!strict

local RunService = game:GetService("RunService")
local RobloxAnalytics = game:GetService("AnalyticsService")

local AnalyticsService = {}
AnalyticsService.__index = AnalyticsService

local allowedEvents = {
  joined = true,
  chapter_started = true,
  chapter_completed = true,
  golden_key_discovered = true,
  run_completed = true,
}

function AnalyticsService.new(enabled: boolean?)
  local self = setmetatable({}, AnalyticsService)
  self.enabled = enabled == true and not RunService:IsStudio()
  return self
end

function AnalyticsService:track(player: Player?, eventName: string, fields: { [string]: any }?)
  if not self.enabled or not allowedEvents[eventName] or not player then
    return
  end
  -- Roblox custom events accept one numeric value. Chapter events use their
  -- bounded numeric chapter; all other events use `1`. Never encode a key ID,
  -- user text, or arbitrary payload.
  local value = 1
  local chapter = fields and tonumber(fields.chapter or fields.stage)
  if chapter and chapter % 1 == 0 and chapter >= 1 and chapter <= 18 then
    value = chapter
  end
  local ok, err = pcall(function()
    RobloxAnalytics:LogCustomEvent(player, eventName, value)
  end)
  if not ok then
    warn(string.format("[Analytics] event failed (%s): %s", eventName, tostring(err)))
  end
end

return AnalyticsService
