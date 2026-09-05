local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local WorldBuilder = require(script.Parent.Parent.WorldGen.WorldBuilder)
local CheckpointService = require(script.Parent.CheckpointService)
local Maid = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Maid"))
local RunStateService = require(script.Parent.RunStateService)
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))
local AnalyticsService = require(script.Parent.AnalyticsService)

local MovementService = require(script.Parent.MovementService)
local AssistService = require(script.Parent.AssistService)

local ObbyService = {}
ObbyService.__index = ObbyService

local function countKeys(profile)
  local count = 0
  for _ in pairs(profile.collectedKeys) do
    count += 1
  end
  return count
end

local function countOwnedKeyTags(root)
  local count = 0
  if not root then
    return count
  end
  for _, part in ipairs(CollectionService:GetTagged("KeyCollectible")) do
    if part:IsDescendantOf(root) then
      count += 1
    end
  end
  return count
end

local function getChapterPresentation(stages, stageIndex)
  local stage = stages[stageIndex]
  if not stage or not stage.model then
    return {}
  end
  return {
    chapterId = stage.stageId,
    chapterName = stage.model:GetAttribute("ChapterName"),
    mechanic = stage.model:GetAttribute("PrimaryMechanic"),
    flavor = stage.model:GetAttribute("ChapterFlavor"),
  }
end

local function bindSettings(self)
  local events = ReplicatedStorage:FindFirstChild("SharedEvents")
  local event = events and events:FindFirstChild(RemoteContracts.SetSettings.name)
  if not event then
    return
  end
  local lastCall = {}
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
  end))
  local allowed = {
    reducedMotion = true,
    reduceFlashes = true,
    highContrast = true,
    largeText = true,
    lowParticles = true,
    showTimer = true,
    masterVolume = "volume",
    musicVolume = "volume",
    sfxVolume = "volume",
    uiScale = "scale",
  }
  self.maid:Give(event.OnServerEvent:Connect(function(player, key, enabled)
    if type(key) ~= "string" or not allowed[key] then
      return
    end
    if allowed[key] == true and type(enabled) ~= "boolean" then
      return
    end
    local minimum = allowed[key] == "scale" and 0.8 or 0
    local maximum = allowed[key] == "scale" and 1.5 or 1
    if
      (allowed[key] == "volume" or allowed[key] == "scale")
      and (type(enabled) ~= "number" or enabled ~= enabled or enabled < minimum or enabled > maximum)
    then
      return
    end
    if not self.checkpoints:isLoaded(player) then
      return
    end
    local now = os.clock()
    if now - (lastCall[player] or 0) < 0.2 then
      return
    end
    lastCall[player] = now
    local profile = self.checkpoints:getProfile(player)
    profile.settings[key] = enabled
  end))
end

local function bindRunModes(self)
  local events = ReplicatedStorage:FindFirstChild("SharedEvents")
  local event = events and events:FindFirstChild(RemoteContracts.SetMode.name)
  if not event then
    return
  end
  local lastCall = {}
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
  end))
  self.maid:Give(event.OnServerEvent:Connect(function(player, mode)
    if type(mode) ~= "string" then
      return
    end
    -- Practice requires a separately authorized chapter selection below; it
    -- must never be entered through the generic mode remote.
    if mode == "Practice" then
      return
    end
    if not self.checkpoints:isLoaded(player) then
      return
    end
    if mode == "TimeTrial" and self.checkpoints:getProfile(player).completionCount < 1 then
      return
    end
    local now = os.clock()
    if now - (lastCall[player] or 0) < 1 then
      return
    end
    lastCall[player] = now
    if not self.runState:setMode(player, mode) then
      return
    end
    self.analytics:resetRun(player)
    if self.assists then
      self.assists.states[player] = nil
    end
    player:SetAttribute("Assisted", false)
    if mode == "TimeTrial" then
      self.checkpoints:resetForTimeTrial(player)
      if self.world.startGate then
        self.checkpoints:teleportToCFrame(player, self.world.model.SpawnPad.CFrame + Vector3.new(0, 4, 0))
      end
    elseif mode == "Adventure" then
      self.checkpoints:resetForAdventure(player)
      if self.world.startGate then
        self.checkpoints:teleportToCFrame(player, self.world.model.SpawnPad.CFrame + Vector3.new(0, 4, 0))
      end
    end
    self.world.progressEvent:FireClient(player, {
      stage = player:GetAttribute("Checkpoint") or 0,
      total = self.world.totalStages,
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      mode = mode,
      runStarted = mode ~= "TimeTrial",
      elapsedMs = 0,
    })
  end))
end

local function bindPracticeStage(self)
  local events = ReplicatedStorage:FindFirstChild("SharedEvents")
  local event = events and events:FindFirstChild(RemoteContracts.PracticeStage.name)
  if not event then
    return
  end
  local lastCall = {}
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
  end))
  self.maid:Give(event.OnServerEvent:Connect(function(player, stage)
    if type(stage) ~= "number" or stage % 1 ~= 0 or stage < 1 or stage > self.world.totalStages then
      return
    end
    if os.clock() - (lastCall[player] or 0) < 1 then
      return
    end
    if not self.checkpoints:isLoaded(player) then
      return
    end
    local profile = self.checkpoints:getProfile(player)
    if profile.completionCount < 1 or profile.highestChapter < stage then
      return
    end
    lastCall[player] = os.clock()
    self.runState:setMode(player, "Practice")
    if not self.checkpoints:setPracticeCheckpoint(player, stage) then
      return
    end
    self.checkpoints:teleportToCFrame(player, self.world.stages[stage].entrance + Vector3.new(0, 4, 0))
    self.world.progressEvent:FireClient(player, {
      stage = stage - 1,
      total = self.world.totalStages,
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      mode = "Practice",
    })
  end))
end

function ObbyService.new()
  if ObbyService._instance then
    return ObbyService._instance
  end
  local self = setmetatable({}, ObbyService)
  self.maid = Maid.new()
  self.behaviors = {}
  self.clock = 0
  self.cosmeticClock = 0
  self.analytics = AnalyticsService.new(GameConfig.EnableAnalytics)
  self.queryClock = 0
  self.riderQueryClock = 0
  self.world = WorldBuilder.buildWorld(GameConfig.Seed)
  self.world.stateFunction.OnServerInvoke = function(player)
    local run = self.runState and self.runState:get(player)
    local stage = player:GetAttribute("Checkpoint") or 0
    return {
      stage = stage,
      total = self.world.totalStages,
      mode = player:GetAttribute("RunMode") or "Adventure",
      ready = self.checkpoints ~= nil and self.checkpoints:isLoaded(player) or false,
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      keys = countKeys(self.checkpoints and self.checkpoints:getProfile(player) or { collectedKeys = {} }),
      totalKeys = self.totalKeys,
      collectedKeys = self.checkpoints and self.checkpoints:getProfile(player).collectedKeys or {},
      settings = self.checkpoints and self.checkpoints:getProfile(player).settings or {},
      medals = self.checkpoints and self.checkpoints:getProfile(player).medals or {},
      runStarted = run and run.running or false,
      elapsedMs = self.runState and math.floor(self.runState:getElapsed(player) * 1000) or 0,
      chapter = getChapterPresentation(self.world.stages, math.min(stage + 1, self.world.totalStages)),
      assist = self.assists and self.assists:snapshot(player) or {},
    }
  end
  self.runState = RunStateService.new(self.world.totalStages, GameConfig.MinimumTimeTrialSeconds)
  -- Count authored collectibles before CheckpointService can emit the first
  -- initialized state to a player-loading task.
  self.totalKeys = countOwnedKeyTags(self.world.model)
  self.checkpoints = CheckpointService.new(
    self.world.stages,
    self.world.progressEvent,
    self.runState,
    self.analytics,
    function()
      return self.totalKeys
    end
  )
  self.checkpoints:bindCheckpoints()
  self.keyProgress = {}
  self.collectedKeys = {}
  bindSettings(self)
  bindRunModes(self)
  bindPracticeStage(self)
  self:scanBehaviors()
  self:hookCommands()
  self:startHeartbeat()
  ObbyService._instance = self
  workspace:SetAttribute("ObbyServiceReady", true)
  return self
end

function ObbyService:hookCommands()
  local function isAllowed(player)
    if RunService:IsStudio() then
      return true
    end
    for _, id in ipairs(GameConfig.AllowlistUserIds) do
      if id == player.UserId then
        return true
      end
    end
    return false
  end

  local lastCommand = {}
  local function dispatch(player, msg)
    if not GameConfig.DevCommandsEnabled or not isAllowed(player) then
      return
    end
    local now = os.clock()
    if now - (lastCommand[player] or 0) < GameConfig.DevCommandCooldownSeconds then
      return
    end
    local command, arg = string.match(msg, "^/(%w+)%s*(.-)%s*$")
    if command == "rebuild" then
      lastCommand[player] = now
      self:rebuild(self.world.seed)
    elseif command == "reseed" then
      local newSeed = math.floor(tonumber(arg) or os.time())
      if newSeed < 0 or newSeed > GameConfig.MaxDevSeed then
        return
      end
      lastCommand[player] = now
      self:rebuild(newSeed)
    elseif command == "stage" then
      local target = tonumber(arg)
      local maxStage = math.min(GameConfig.MaxDevStage, #self.world.stages)
      if target and target % 1 == 0 and target >= 1 and target <= maxStage then
        lastCommand[player] = now
        self.checkpoints:teleportToStage(player, target)
      end
    end
  end

  local modernCommands = typeof(TextChatService) == "Instance"
  if modernCommands then
    for _, definition in ipairs({
      { name = "ToadsRebuildCommand", alias = "/rebuild" },
      { name = "ToadsReseedCommand", alias = "/reseed" },
      { name = "ToadsStageCommand", alias = "/stage" },
    }) do
      local command = TextChatService:FindFirstChild(definition.name)
      if not command then
        command = Instance.new("TextChatCommand")
        command.Name = definition.name
        command.PrimaryAlias = definition.alias
        command.Parent = TextChatService
      end
      self.maid:Give(command.Triggered:Connect(function(textSource, unfilteredText)
        local player = Players:GetPlayerByUserId(textSource.UserId)
        if player then
          dispatch(player, unfilteredText)
        end
      end))
    end
  else
    for _, player in ipairs(Players:GetPlayers()) do
      self.maid:Give(player.Chatted:Connect(function(msg)
        dispatch(player, msg)
      end))
    end
    self.maid:Give(Players.PlayerAdded:Connect(function(player)
      self.maid:Give(player.Chatted:Connect(function(msg)
        dispatch(player, msg)
      end))
    end))
  end
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCommand[player] = nil
  end))
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    self.keyProgress[player] = nil
    self.collectedKeys[player] = nil
  end))
end

function ObbyService:registerKey(part)
  local keyId = part:GetAttribute("KeyId")
  if type(keyId) ~= "string" or #keyId == 0 or #keyId > 80 then
    warn("[Keys] collectible missing stable KeyId", part:GetFullName())
    return
  end
  self.totalKeys = self.totalKeys + 1
  self.maid:Give(part.Touched:Connect(function(hit)
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if
      not player
      or not part.Parent
      or not self.world.model
      or not part:IsDescendantOf(self.world.model)
      or not self.checkpoints:isLoaded(player)
    then
      return
    end
    local root = hit.Parent:FindFirstChild("HumanoidRootPart")
    local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 or (root.Position - part.Position).Magnitude > 18 then
      return
    end
    self.collectedKeys[player] = self.collectedKeys[player] or {}
    if self.collectedKeys[player][keyId] or not self.checkpoints:markKey(player, keyId) then
      return
    end
    self.collectedKeys[player][keyId] = true
    self.checkpoints:getProfile(player).medals["Explorer" .. tostring(part:GetAttribute("StageIndex"))] = true
    self.analytics:track(player, "CollectibleFound", { stage = part:GetAttribute("StageIndex") })
    self.keyProgress[player] = 0
    for _ in pairs(self.checkpoints:getProfile(player).collectedKeys) do
      self.keyProgress[player] += 1
    end
    local sound = part:FindFirstChildOfClass("Sound")
    if sound then
      sound:Play()
    end
    if self.world.keyEvent then
      self.world.keyEvent:FireClient(player, {
        found = self.keyProgress[player],
        total = self.totalKeys,
        keyId = keyId,
      })
    end
  end))
end

function ObbyService:scanBehaviors()
  local events = ReplicatedStorage.SharedEvents
  self.assists = AssistService.new(self.checkpoints, self.analytics, events.Assistance, self.maid)
  for _, part in ipairs(CollectionService:GetTagged("KeyCollectible")) do
    if part:IsDescendantOf(self.world.model) then
      self:registerKey(part)
    end
  end
  self.maid:Give(self.world.startGate.Touched:Connect(function(hit)
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if player and self.checkpoints:isLoaded(player) then
      self.runState:startAtGate(player, self.world.startGate)
    end
  end))
  -- Hazard contacts are sampled by MovementService; toggling CanTouch must not own connections.
  self.totalKeys = countOwnedKeyTags(self.world.model)
end

function ObbyService:startHeartbeat()
  MovementService.start(self.world, self.maid, function(player, cause)
    self.assists:fail(player, cause)
  end)
end

function ObbyService:rebuild(seed)
  local retained = self.checkpoints and self.checkpoints:exportSessions() or {}
  self.maid:DoCleaning()
  if self.checkpoints then
    self.checkpoints:destroy()
  end
  if self.runState then
    self.runState:destroy()
  end
  if self.world and self.world.model then
    self.world.model:Destroy()
  end
  self.clock = 0
  self.cosmeticClock = 0
  self.queryClock = 0
  self.riderQueryClock = 0
  self.world = WorldBuilder.buildWorld(seed)
  self.world.stateFunction.OnServerInvoke = function(player)
    local run = self.runState and self.runState:get(player)
    local stage = player:GetAttribute("Checkpoint") or 0
    return {
      stage = stage,
      total = self.world.totalStages,
      mode = player:GetAttribute("RunMode") or "Adventure",
      ready = self.checkpoints ~= nil and self.checkpoints:isLoaded(player) or false,
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      keys = countKeys(self.checkpoints and self.checkpoints:getProfile(player) or { collectedKeys = {} }),
      totalKeys = self.totalKeys,
      collectedKeys = self.checkpoints and self.checkpoints:getProfile(player).collectedKeys or {},
      settings = self.checkpoints and self.checkpoints:getProfile(player).settings or {},
      medals = self.checkpoints and self.checkpoints:getProfile(player).medals or {},
      runStarted = run and run.running or false,
      elapsedMs = self.runState and math.floor(self.runState:getElapsed(player) * 1000) or 0,
      chapter = getChapterPresentation(self.world.stages, math.min(stage + 1, self.world.totalStages)),
      assist = self.assists and self.assists:snapshot(player) or {},
    }
  end
  self.runState = RunStateService.new(self.world.totalStages, GameConfig.MinimumTimeTrialSeconds)
  self.totalKeys = countOwnedKeyTags(self.world.model)
  self.checkpoints = CheckpointService.new(
    self.world.stages,
    self.world.progressEvent,
    self.runState,
    self.analytics,
    function()
      return self.totalKeys
    end,
    retained
  )
  self.checkpoints:bindCheckpoints()
  self.keyProgress = {}
  bindSettings(self)
  bindRunModes(self)
  bindPracticeStage(self)
  self:scanBehaviors()
  self:hookCommands()
  self:startHeartbeat()
end

return ObbyService
