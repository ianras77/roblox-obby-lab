local Players = game:GetService("Players")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))
local Maid = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("Maid"))
local DataStoreWrapper = require(script.Parent.DataStoreServiceWrapper)
local ProfileSchema = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("ProfileSchema"))

local activeService = nil
local shutdownBound = false

local CheckpointService = {}
CheckpointService.__index = CheckpointService

function CheckpointService.new(stages, progressEvent, runState)
  local self = setmetatable({}, CheckpointService)
  self.stages = stages
  self.maid = Maid.new()
  self.progressEvent = progressEvent
  self.runState = runState
  self.store = DataStoreWrapper.new(GameConfig.DataStoreName)
  self.loaded = {}
  self.profiles = {}
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
  self.maid:Give(player.CharacterAdded:Connect(function()
    self:teleportToSavedCheckpoint(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
      self.maid:Give(humanoid.Died:Connect(function()
        local profile = self:getProfile(player)
        profile.totalDeaths += 1
      end))
    end
  end))
  if self.progressEvent then
    self.progressEvent:FireClient(player, {
      stage = player:GetAttribute("Checkpoint") or 0,
      total = #self.stages,
      initialized = true,
    })
  end
end

function CheckpointService:hookPlayers()
  self.maid:Give(Players.PlayerAdded:Connect(function(player)
    self:initializePlayer(player)
  end))

  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    self:saveCheckpoint(player)
    self.loaded[player] = nil
    self.profiles[player] = nil
  end))
end

function CheckpointService:loadCheckpoint(player)
  local saved = self.store:GetAsync("player:" .. tostring(player.UserId))
  self.loaded[player] = true
  local profile = ProfileSchema.sanitize(saved)
  self.profiles[player] = profile
  profile.highestChapter = math.clamp(profile.highestChapter, 0, #self.stages)
  if profile.highestChapter > 0 then
    player:SetAttribute("Checkpoint", profile.highestChapter)
    player:SetAttribute("CheckpointId", self.stages[profile.highestChapter].stageId)
  end
end

function CheckpointService:saveCheckpoint(player)
  if not GameConfig.SaveCheckpoints then
    return
  end
  local profile = self.profiles[player] or ProfileSchema.default()
  profile.highestChapter = player:GetAttribute("Checkpoint") or 0
  self.store:SetAsync("player:" .. tostring(player.UserId), profile)
end

function CheckpointService:getProfile(player)
  return self.profiles[player] or ProfileSchema.default()
end

function CheckpointService:markKey(player, keyId: string): boolean
  local profile = self:getProfile(player)
  if profile.collectedKeys[keyId] then
    return false
  end
  profile.collectedKeys[keyId] = true
  self.profiles[player] = profile
  return true
end

function CheckpointService:bindCheckpoints()
  for _, stage in ipairs(self.stages) do
    local cp = stage.checkpoint
    if cp then
      self.maid:Give(cp.Touched:Connect(function(hit)
        self:onCheckpointTouched(stage.stageIndex, cp, hit)
      end))
    end
  end
end

function CheckpointService:onCheckpointTouched(stageIndex, checkpoint, hit)
  local player = Players:GetPlayerFromCharacter(hit.Parent)
  if not player then
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
    local previous = player:GetAttribute("Checkpoint") or 0
    if stageIndex <= previous then
      return
    end
    player:SetAttribute("Checkpoint", stageIndex)
    player:SetAttribute("CheckpointId", checkpoint:GetAttribute("StageId"))
    local stageModel = checkpoint.Parent
    local sound = checkpoint:FindFirstChildOfClass("Sound")
    if sound then
      sound:Play()
    end
    local burst = checkpoint:FindFirstChild("CheckpointBurst")
    if burst then
      burst:Emit(24)
    end
    local elapsed, eligible = self.runState and self.runState:onChapterReached(player, stageIndex)
    if elapsed and eligible then
      local profile = self:getProfile(player)
      profile.completionCount += 1
      if not profile.bestRunMs or elapsed * 1000 < profile.bestRunMs then
        profile.bestRunMs = math.floor(elapsed * 1000)
      end
    end
    if self.progressEvent then
      self.progressEvent:FireClient(player, {
        stage = stageIndex,
        total = #self.stages,
        mode = player:GetAttribute("RunMode") or "Adventure",
        elapsedMs = elapsed and math.floor(elapsed * 1000) or nil,
        timeTrialEligible = eligible,
        bestRunMs = self:getProfile(player).bestRunMs,
        deaths = self:getProfile(player).totalDeaths,
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
        evt:FireClient(player, { stage = stageIndex })
      end
    end
  end
end

function CheckpointService:teleportToStage(player, targetStage)
  for _, stage in ipairs(self.stages) do
    if stage.stageIndex == targetStage then
      local cp = stage.checkpoint
      if cp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = cp.CFrame + Vector3.new(0, 5, 0)
      end
      return true
    end
  end
  return false
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
  if activeService == self then
    activeService = nil
  end
end

return CheckpointService
