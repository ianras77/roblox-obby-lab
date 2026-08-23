local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("GameConfig"))
local Maid = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("Maid"))
local DataStoreWrapper = require(script.Parent.DataStoreServiceWrapper)
local ProfileSchema = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("ProfileSchema"))

local CheckpointService = {}
CheckpointService.__index = CheckpointService

function CheckpointService.new(stages, progressEvent)
  local self = setmetatable({}, CheckpointService)
  self.stages = stages
  self.maid = Maid.new()
  self.progressEvent = progressEvent
  self.store = DataStoreWrapper.new(GameConfig.DataStoreName)
  self:hookPlayers()
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
  end))
end

function CheckpointService:loadCheckpoint(player)
  local saved = self.store:GetAsync(player.UserId)
  local profile = ProfileSchema.sanitize(saved)
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
  local profile = ProfileSchema.sanitize(nil)
  profile.highestChapter = player:GetAttribute("Checkpoint") or 0
  self.store:SetAsync(player.UserId, profile)
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
  if humanoidRoot then
    local previous = player:GetAttribute("Checkpoint") or 0
    if stageIndex <= previous then
      return
    end
    player:SetAttribute("Checkpoint", stageIndex)
    player:SetAttribute("CheckpointId", checkpoint:GetAttribute("StageId"))
    local sound = checkpoint:FindFirstChildOfClass("Sound")
    if sound then
      sound:Play()
    end
    local burst = checkpoint:FindFirstChild("CheckpointBurst")
    if burst then
      burst:Emit(24)
    end
    if self.progressEvent then
      self.progressEvent:FireClient(player, { stage = stageIndex, total = #self.stages })
    end
    if stageIndex == #self.stages then
      local celebrator = Instance.new("ParticleEmitter")
      celebrator.Texture = "rbxassetid://258128463"
      celebrator.Lifetime = NumberRange.new(1, 1.4)
      celebrator.Speed = NumberRange.new(28, 36)
      celebrator.Rate = 80
      celebrator.Parent = checkpoint
      celebrator:Emit(80)
      Debris:AddItem(celebrator, 2)
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
end

return CheckpointService
