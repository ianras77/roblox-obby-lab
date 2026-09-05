local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Util.AssistRules)
local Definitions = require(ReplicatedStorage.Config.StageDefinitions)
local AssistService = {}
AssistService.__index = AssistService
function AssistService.new(checkpoints, analytics, remote, maid)
  local self =
    setmetatable({ checkpoints = checkpoints, analytics = analytics, remote = remote, states = {} }, AssistService)
  checkpoints.onDeath = function(player)
    local state = self:get(player)
    if os.clock() - state.lastFailure >= 1 then
      state.failures += 1
      state.attempts += 1
      state.lastCause = "reset"
      state.lastFailure = os.clock()
      self.analytics:progress(player, "Fail", state.stage)
      self:send(player)
    end
  end
  maid:Give(function()
    checkpoints.onDeath = nil
  end)
  maid:Give(Players.PlayerRemoving:Connect(function(player)
    self.states[player] = nil
  end))
  maid:Give(remote.OnServerEvent:Connect(function(player, action)
    if not checkpoints:isLoaded(player) then
      return
    end
    local state = self:get(player)
    if os.clock() - (state.lastRequest or -2) < 1 then
      return
    end
    state.lastRequest = os.clock()
    if action == "Reset" then
      self:fail(player, "reset")
    elseif action == "Help" and Rules.state(state.failures, os.clock() - state.started).help then
      checkpoints:getProfile(player).assistedChapters[tostring(state.stage)] = true
      state.assisted = true
      player:SetAttribute("Assisted", true)
      self.analytics:track(player, "AssistActivated", { stage = state.stage })
      self.analytics:track(player, "SkipUsed", { stage = state.stage })
      local stage = checkpoints.stages[state.stage]
      checkpoints:teleportToCFrame(player, stage.safeSpawn)
      local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
      if root then
        checkpoints:onCheckpointTouched(state.stage, stage.checkpoint, root)
      end
    end
  end))
  local elapsed = 0
  maid:Give(RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 1 then
      return
    end
    elapsed = 0
    for _, player in ipairs(Players:GetPlayers()) do
      if checkpoints:isLoaded(player) then
        local state = self:get(player)
        self:send(player)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
          analytics:funnel(player, 2)
        end
        if os.clock() - state.started > 90 then
          player:SetAttribute("HelpAvailable", true)
        end
      end
    end
  end))
  return self
end
function AssistService:get(player)
  local stage = math.min((player:GetAttribute("Checkpoint") or 0) + 1, #Definitions)
  local state = self.states[player]
  if not state or state.stage ~= stage then
    state = { stage = stage, failures = 0, attempts = 1, started = os.clock(), assisted = false, lastFailure = -2 }
    self.states[player] = state
    player:SetAttribute("HelpAvailable", false)
    self.analytics:progress(player, "Start", stage)
  end
  return state
end
function AssistService:snapshot(player)
  local state = self:get(player)
  local rules = Rules.state(state.failures, os.clock() - state.started)
  return {
    stage = state.stage,
    attempts = state.attempts,
    failures = state.failures,
    help = rules.help,
    grace = rules.grace,
    assisted = state.assisted,
    hint = rules.hint and Definitions[state.stage].teachingGoal or "Follow >>. Golden detours are optional.",
  }
end
function AssistService:send(player)
  local snapshot = self:snapshot(player)
  if (player:GetAttribute("Checkpoint") or 0) >= #Definitions then
    snapshot.help = false
  end
  self.remote:FireClient(player, snapshot)
end
function AssistService:fail(player, cause)
  if not self.checkpoints:isLoaded(player) then
    return
  end
  local now = os.clock()
  local state = self:get(player)
  if (cause == "hazard" and now < (player:GetAttribute("GraceUntil") or 0)) or now - state.lastFailure < 1 then
    return
  end
  self.checkpoints:getProfile(player).totalDeaths += 1
  state.lastFailure = now
  state.failures += 1
  state.attempts += 1
  state.lastCause = cause
  if state.failures >= 3 then
    state.assisted = true
    player:SetAttribute("Assisted", true)
    self.checkpoints:getProfile(player).assistedChapters[tostring(state.stage)] = true
    self.analytics:track(player, "AssistActivated", { stage = state.stage })
  end
  self.analytics:progress(player, "Fail", state.stage)
  self.checkpoints:teleportToSavedCheckpoint(player)
  player:SetAttribute("GraceUntil", now + (state.failures >= 3 and 3 or 1))
  self:send(player)
  self.analytics:progress(player, "Start", state.stage)
end
return AssistService
