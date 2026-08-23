local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))
local Maid = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("Maid"))
local DataStoreWrapper = require(script.Parent.DataStoreServiceWrapper)
local ProfileSchema = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("ProfileSchema"))
local ProgressionRules =
  require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("ProgressionRules"))

local activeService = nil
local shutdownBound = false
local PLAYER_COLLISION_GROUP = "ToadsPlayers"

local function configurePlayerCollision(character)
  pcall(function()
    PhysicsService:RegisterCollisionGroup(PLAYER_COLLISION_GROUP)
  end)
  pcall(function()
    PhysicsService:CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP, PLAYER_COLLISION_GROUP, false)
  end)
  for _, descendant in ipairs(character:GetDescendants()) do
    if descendant:IsA("BasePart") then
      descendant.CollisionGroup = PLAYER_COLLISION_GROUP
    end
  end
end

local CheckpointService = {}
CheckpointService.__index = CheckpointService

function CheckpointService.new(stages, progressEvent, runState, analytics, totalKeysProvider)
  local self = setmetatable({}, CheckpointService)
  self.stages = stages
  self.maid = Maid.new()
  self.progressEvent = progressEvent
  self.runState = runState
  self.analytics = analytics
  self.totalKeysProvider = totalKeysProvider
  self.store = DataStoreWrapper.new(GameConfig.DataStoreName)
  self.loaded = {}
  self.persistenceAllowed = {}
  self.profiles = {}
  self.deathConnections = {}
  self.collisionConnections = {}
  activeService = self
  self:hookPlayers()
  local autosaveActive = true
  self.maid:Give(function()
    autosaveActive = false
  end)
  task.spawn(function()
    while true do
      task.wait(GameConfig.AutosaveSeconds)
      if not autosaveActive then
        return
      end
      for _, player in ipairs(Players:GetPlayers()) do
        if self.loaded[player] then
          self:saveCheckpoint(player)
        end
      end
    end
  end)
  if not shutdownBound then
    shutdownBound = true
    game:BindToClose(function()
      if activeService then
        for _, player in ipairs(Players:GetPlayers()) do
          activeService:saveCheckpoint(player)
        end
      end
    end)
  end
  for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
      self:initializePlayer(player)
    end)
  end
  return self
end

function CheckpointService:initializePlayer(player)
  self:loadCheckpoint(player)
  if not player.Parent then
    self.loaded[player] = nil
    self.persistenceAllowed[player] = nil
    self.profiles[player] = nil
    return
  end
  if self.analytics then
    self.analytics:track(player, "joined")
  end
  self.maid:Give(player.CharacterAdded:Connect(function(character)
    if self.collisionConnections[player] then
      self.collisionConnections[player]:Disconnect()
    end
    configurePlayerCollision(character)
    self.collisionConnections[player] = character.DescendantAdded:Connect(function(descendant)
      if descendant:IsA("BasePart") then
        descendant.CollisionGroup = PLAYER_COLLISION_GROUP
      end
    end)
    self:teleportToSavedCheckpoint(player)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
      if self.deathConnections[player] then
        self.deathConnections[player]:Disconnect()
      end
      self.deathConnections[player] = humanoid.Died:Connect(function()
        local profile = self:getProfile(player)
        profile.totalDeaths += 1
      end)
    end
  end))
  self.maid:Give(player.CharacterRemoving:Connect(function()
    if self.collisionConnections[player] then
      self.collisionConnections[player]:Disconnect()
      self.collisionConnections[player] = nil
    end
  end))
  if player.Character then
    configurePlayerCollision(player.Character)
  end
  if self.progressEvent then
    local run = self.runState and self.runState:get(player)
    self.progressEvent:FireClient(player, {
      stage = player:GetAttribute("Checkpoint") or 0,
      total = #self.stages,
      initialized = true,
      mode = player:GetAttribute("RunMode") or "Adventure",
      highestChapter = self:getProfile(player).highestChapter,
      runStarted = run and run.running or false,
      elapsedMs = self.runState and math.floor(self.runState:getElapsed(player) * 1000) or 0,
    })
  end
end

function CheckpointService:hookPlayers()
  self.maid:Give(Players.PlayerAdded:Connect(function(player)
    self:initializePlayer(player)
  end))

  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    self:saveCheckpoint(player)
    if self.deathConnections[player] then
      self.deathConnections[player]:Disconnect()
      self.deathConnections[player] = nil
    end
    if self.collisionConnections[player] then
      self.collisionConnections[player]:Disconnect()
      self.collisionConnections[player] = nil
    end
    self.loaded[player] = nil
    self.persistenceAllowed[player] = nil
    self.profiles[player] = nil
  end))
end

function CheckpointService:loadCheckpoint(player)
  player:SetAttribute("ProfileLoadStatus", "Loading")
  player:SetAttribute("Checkpoint", 0)
  player:SetAttribute("CheckpointId", nil)
  local saved, loadSucceeded = self.store:GetAsync("player:" .. tostring(player.UserId))
  if not player.Parent then
    return
  end
  -- A failed read still gets an ephemeral profile so the player can play;
  -- only a confirmed read authorizes writes back to the store.
  self.loaded[player] = true
  self.persistenceAllowed[player] = loadSucceeded == true
  local profile = ProfileSchema.sanitize(saved)
  self.profiles[player] = profile
  if not self.persistenceAllowed[player] then
    player:SetAttribute("ProfileLoadStatus", "Failed")
    player:SetAttribute("ProfileSaveStatus", "Skipped")
    warn(string.format("[DataStore] Profile load failed for %s; writes are disabled", player.Name))
    return
  end
  player:SetAttribute("ProfileLoadStatus", "Ready")
  profile.highestChapter = math.clamp(profile.highestChapter, 0, #self.stages)
  if profile.highestChapter > 0 then
    player:SetAttribute("Checkpoint", profile.highestChapter)
    player:SetAttribute("CheckpointId", self.stages[profile.highestChapter].stageId)
  end
  if player.Character then
    self:teleportToSavedCheckpoint(player)
  end
end

function CheckpointService:saveCheckpoint(player)
  if not GameConfig.SaveCheckpoints or not self:isLoaded(player) or not self.persistenceAllowed[player] then
    return
  end
  local profile = self.profiles[player] or ProfileSchema.default()
  local liveCheckpoint = ProgressionRules.normalizeCheckpoint(player:GetAttribute("Checkpoint"))
  profile.highestChapter = math.clamp(math.max(profile.highestChapter, liveCheckpoint), 0, #self.stages)
  self.profiles[player] = profile
  local snapshot = ProfileSchema.sanitize(profile)
  local saved = self.store:SetAsync("player:" .. tostring(player.UserId), snapshot)
  local saveStatus = not self.store:isEnabled() and "Skipped" or (saved and "Saved" or "Failed")
  player:SetAttribute("ProfileSaveStatus", saveStatus)
  if saved then
    player:SetAttribute("ProfileSavedAt", os.time())
  end
end

function CheckpointService:getProfile(player)
  return self.profiles[player] or ProfileSchema.default()
end

function CheckpointService:isLoaded(player): boolean
  return self.loaded[player] == true and self.profiles[player] ~= nil
end

function CheckpointService:resetForTimeTrial(player)
  if not self:isLoaded(player) then
    return false
  end
  player:SetAttribute("Checkpoint", 0)
  player:SetAttribute("CheckpointId", nil)
  return true
end

function CheckpointService:resetForAdventure(player): boolean
  if not self:isLoaded(player) then
    return false
  end
  player:SetAttribute("Checkpoint", 0)
  player:SetAttribute("CheckpointId", nil)
  return true
end

function CheckpointService:setPracticeCheckpoint(player, targetStage): boolean
  if not self:isLoaded(player) or type(targetStage) ~= "number" or targetStage % 1 ~= 0 then
    return false
  end
  if self:getProfile(player).highestChapter < targetStage then
    return false
  end
  local stage = self.stages[targetStage]
  if not stage or not stage.checkpoint then
    return false
  end
  player:SetAttribute("Checkpoint", targetStage)
  player:SetAttribute("CheckpointId", stage.checkpoint:GetAttribute("StageId"))
  return true
end

function CheckpointService:markKey(player, keyId: string): boolean
  local profile = self:getProfile(player)
  if profile.collectedKeys[keyId] then
    return false
  end
  local keyCount = 0
  for _ in pairs(profile.collectedKeys) do
    keyCount += 1
  end
  if keyCount >= ProfileSchema.MaxCollectedKeys then
    return false
  end
  profile.collectedKeys[keyId] = true
  self.profiles[player] = profile
  return true
end

function CheckpointService:bindCheckpoints()
  for _, stage in ipairs(self.stages) do
    local cp = stage.checkpoint
    if cp and cp:IsA("BasePart") then
      self.maid:Give(cp.Touched:Connect(function(hit)
        self:onCheckpointTouched(stage.stageIndex, cp, hit)
      end))
    else
      warn(string.format("[Checkpoint] stage %s has no valid checkpoint", tostring(stage.stageIndex)))
    end
  end
end

function CheckpointService:onCheckpointTouched(stageIndex, checkpoint, hit)
  local stage = self.stages[stageIndex]
  if
    not stage
    or stage.checkpoint ~= checkpoint
    or not checkpoint:IsDescendantOf(stage.model)
    or checkpoint:GetAttribute("StageIndex") ~= stageIndex
    or checkpoint:GetAttribute("StageId") ~= stage.stageId
  then
    warn(string.format("[Checkpoint] rejected invalid runtime checkpoint for stage %s", tostring(stageIndex)))
    return
  end
  local player = Players:GetPlayerFromCharacter(hit.Parent)
  if not player then
    return
  end
  if not self:isLoaded(player) then
    return
  end
  local humanoidRoot = hit.Parent:FindFirstChild("HumanoidRootPart")
  local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
  if
    humanoidRoot
    and humanoid
    and humanoid.Health > 0
    and (humanoidRoot.Position - checkpoint.Position).Magnitude <= 18
  then
    local previous = player:GetAttribute("Checkpoint")
    if not ProgressionRules.canAdvance(previous, stageIndex, #self.stages) then
      return
    end
    player:SetAttribute("Checkpoint", stageIndex)
    player:SetAttribute("CheckpointId", checkpoint:GetAttribute("StageId"))
    local checkpointProfile = self:getProfile(player)
    checkpointProfile.highestChapter = math.max(checkpointProfile.highestChapter, stageIndex)
    self.profiles[player] = checkpointProfile
    if self.analytics then
      self.analytics:track(player, "chapter_started", { stage = stageIndex })
      self.analytics:track(player, "chapter_completed", { stage = stageIndex })
    end
    local stageModel = stage.model
    local sound = checkpoint:FindFirstChildOfClass("Sound")
    if sound then
      sound:Play()
    end
    local burst = checkpoint:FindFirstChild("CheckpointBurst")
    if burst then
      burst:Emit(24)
    end
    local elapsed, eligible
    if self.runState then
      elapsed, eligible = self.runState:onChapterReached(player, stageIndex)
      local run = self.runState:get(player)
      local split = run.chapterSplits[stageIndex - 1]
      if split and player:GetAttribute("RunMode") == "TimeTrial" then
        local splitProfile = self:getProfile(player)
        local splitMs = math.floor(split * 1000)
        local splitKey = tostring(stageIndex - 1)
        if not splitProfile.bestChapterMs[splitKey] or splitMs < splitProfile.bestChapterMs[splitKey] then
          splitProfile.bestChapterMs[splitKey] = splitMs
        end
      end
    end
    if elapsed and eligible then
      if self.analytics then
        self.analytics:track(player, "run_completed", { mode = player:GetAttribute("RunMode") })
      end
      local completionProfile = self:getProfile(player)
      completionProfile.completionCount += 1
      if
        player:GetAttribute("RunMode") == "TimeTrial"
        and (not completionProfile.bestRunMs or elapsed * 1000 < completionProfile.bestRunMs)
      then
        completionProfile.bestRunMs = math.floor(elapsed * 1000)
      end
    end
    if self.progressEvent then
      local run = self.runState and self.runState:get(player)
      self.progressEvent:FireClient(player, {
        stage = stageIndex,
        total = #self.stages,
        mode = player:GetAttribute("RunMode") or "Adventure",
        elapsedMs = elapsed and math.floor(elapsed * 1000) or nil,
        runStarted = run and run.running or false,
        timeTrialEligible = eligible,
        bestRunMs = self:getProfile(player).bestRunMs,
        deaths = self:getProfile(player).totalDeaths,
        bestChapterMs = self:getProfile(player).bestChapterMs,
        chapterId = stage.stageId,
        chapterName = stageModel:GetAttribute("ChapterName") or checkpoint:GetAttribute("StageId"),
        mechanic = stageModel:GetAttribute("PrimaryMechanic"),
        flavor = stageModel:GetAttribute("ChapterFlavor"),
      })
    end
    if stageIndex == #self.stages then
      -- Finale presentation is sent to the completing player only. Shared
      -- checkpoints do not emit a replicated burst for everyone.
      local finale = game:GetService("ReplicatedStorage"):FindFirstChild("SharedEvents")
      local evt = finale and finale:FindFirstChild(GameConfig.FinaleRemote)
      if evt then
        local finaleProfile = self:getProfile(player)
        local foundKeys = 0
        for _ in pairs(finaleProfile.collectedKeys) do
          foundKeys += 1
        end
        evt:FireClient(player, {
          stage = stageIndex,
          mode = player:GetAttribute("RunMode") or "Adventure",
          elapsedMs = elapsed and math.floor(elapsed * 1000) or nil,
          bestRunMs = finaleProfile.bestRunMs,
          deaths = finaleProfile.totalDeaths,
          keys = foundKeys,
          totalKeys = self.totalKeysProvider and self.totalKeysProvider() or nil,
          bestChapterMs = finaleProfile.bestChapterMs,
        })
      end
    end
  end
end

function CheckpointService:teleportToStage(player, targetStage)
  for _, stage in ipairs(self.stages) do
    if stage.stageIndex == targetStage then
      local cp = stage.checkpoint
      local character = player.Character
      local root = character and character:FindFirstChild("HumanoidRootPart")
      if character and not root then
        root = character:WaitForChild("HumanoidRootPart", 5)
      end
      if cp and root and root:IsA("BasePart") then
        root.AssemblyLinearVelocity = Vector3.new()
        root.AssemblyAngularVelocity = Vector3.new()
        root.CFrame = stage.safeSpawn or (cp.CFrame + Vector3.new(0, 5, 0))
        root:SetNetworkOwner(nil)
      end
      return true
    end
  end
  return false
end

function CheckpointService:teleportToCFrame(player, destination: CFrame)
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  if character and not root then
    root = character:WaitForChild("HumanoidRootPart", 5)
  end
  if not root or not root:IsA("BasePart") then
    return false
  end
  root.AssemblyLinearVelocity = Vector3.new()
  root.AssemblyAngularVelocity = Vector3.new()
  root.CFrame = destination
  root:SetNetworkOwner(nil)
  return true
end

function CheckpointService:teleportToSavedCheckpoint(player)
  local target = player:GetAttribute("Checkpoint")
  if not target then
    return
  end
  self:teleportToStage(player, target)
end

function CheckpointService:destroy()
  self.maid:DoCleaning()
  for player, connection in pairs(self.deathConnections) do
    connection:Disconnect()
    self.deathConnections[player] = nil
  end
  if activeService == self then
    activeService = nil
  end
end

return CheckpointService
