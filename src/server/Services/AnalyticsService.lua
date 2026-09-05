--!strict
local RunService = game:GetService("RunService")
local RobloxAnalytics = game:GetService("AnalyticsService")
local Definitions = require(game:GetService("ReplicatedStorage").Config.StageDefinitions)
local AnalyticsService = {}
AnalyticsService.__index = AnalyticsService
local custom = {
  AssistActivated = true,
  SkipUsed = true,
  StageDuration = true,
  StoryCompleteDuration = true,
  CollectibleFound = true,
}
local steps = { "JoinedGame", "FirstMovement", "FirstCheckpoint", "Stage3Complete", "StoryComplete" }
function AnalyticsService.new(enabled)
  return setmetatable(
    { enabled = enabled == true and not RunService:IsStudio(), states = setmetatable({}, { __mode = "k" }) },
    AnalyticsService
  )
end
function AnalyticsService:state(player)
  if not self.states[player] then
    self.states[player] = { seen = {}, started = {}, last = {}, window = os.clock(), count = 0 }
  end
  return self.states[player]
end
function AnalyticsService:emit(player, key, callback, once)
  local state = self:state(player)
  local now = os.clock()
  if once and state.seen[key] then
    return
  end
  if now - (state.last[key] or -2) < 0.5 then
    return
  end
  if now - state.window >= 60 then
    state.window = now
    state.count = 0
  end
  if state.count >= 100 then
    return
  end
  state.seen[key] = true
  state.last[key] = now
  state.count += 1
  if self.enabled then
    local ok = pcall(callback)
    if not ok and not state.warned then
      state.warned = true
      warn("[Analytics] delivery unavailable; gameplay continues")
    end
  end
end
local function fields(player, stage)
  return {
    [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(math.clamp(stage or 1, 1, 18)),
    [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = player:GetAttribute("Assisted") and "yes" or "no",
    [Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = player:GetAttribute("RunMode") == "TimeTrial" and "challenge"
      or "story",
  }
end
function AnalyticsService:funnel(player, step)
  if not steps[step] then
    return
  end
  self:emit(player, "funnel" .. step, function()
    RobloxAnalytics:LogOnboardingFunnelStepEvent(player, step, steps[step])
  end, true)
end
function AnalyticsService:progress(player, status, stage)
  local definition = Definitions[stage]
  if not definition or (status ~= "Start" and status ~= "Fail" and status ~= "Complete") then
    return
  end
  local state = self:state(player)
  if status == "Start" then
    state.started[stage] = state.started[stage] or os.clock()
  elseif status == "Complete" and not state.seen["Complete" .. stage] then
    self:track(player, "StageDuration", { stage = stage, value = os.clock() - (state.started[stage] or os.clock()) })
  end
  self:emit(player, status .. stage, function()
    RobloxAnalytics:LogProgressionEvent(
      player,
      "MainStory",
      Enum.AnalyticsProgressionType[status],
      stage,
      definition.analyticsLevelName,
      fields(player, stage)
    )
  end, status == "Complete")
end
function AnalyticsService:track(player, eventName, payload)
  if not custom[eventName] or not player then
    return
  end
  payload = payload or {}
  local stage = math.clamp(tonumber(payload.stage) or 1, 1, 18)
  local value = math.clamp(tonumber(payload.value) or 1, 0, 86400)
  self:emit(player, eventName .. stage, function()
    RobloxAnalytics:LogCustomEvent(player, eventName, value, fields(player, stage))
  end, true)
end
function AnalyticsService:resetRun(player)
  local state = self:state(player)
  local funnel = {}
  for key, value in pairs(state.seen) do
    if string.sub(key, 1, 6) == "funnel" then
      funnel[key] = value
    end
  end
  state.seen = funnel
  state.started = {}
  state.last = {}
end
return AnalyticsService
