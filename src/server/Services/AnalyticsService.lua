--!strict

local RunService = game:GetService("RunService")

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
  if not self.enabled or not allowedEvents[eventName] then
    return
  end
  -- Keep the integration boundary deliberately small. A production sink can
  -- be added later without allowing clients to submit arbitrary events.
  local _ = player and player.UserId
  local _ = fields
end

return AnalyticsService
