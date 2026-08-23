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
  -- Keep the integration boundary deliberately small. A production sink can
  -- receive only allowlisted events and a fixed low-cardinality value.
  local _ = fields
  local ok, err = pcall(function()
    RobloxAnalytics:LogCustomEvent(player, eventName, 1)
  end)
  if not ok then
    warn(string.format("[Analytics] event failed (%s): %s", eventName, tostring(err)))
  end
end

return AnalyticsService
