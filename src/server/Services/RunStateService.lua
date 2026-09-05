--!strict

local Players = game:GetService("Players")
local Maid = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("Maid"))
local RunRules = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("RunRules"))

local RunStateService = {}
RunStateService.__index = RunStateService

export type RunState = {
  mode: string,
  startedAt: number?,
  running: boolean,
  completedAt: number?,
  chapterStartedAt: { [number]: number },
  chapterSplits: { [number]: number },
}

function RunStateService.new(totalStages: number, minimumTimeTrialSeconds: number)
  local self = setmetatable({}, RunStateService)
  self.maid = Maid.new()
  self.totalStages = totalStages
  self.minimumTimeTrialSeconds = math.max(0, minimumTimeTrialSeconds or 0)
  self.states = {} :: { [Player]: RunState }
  for _, player in ipairs(Players:GetPlayers()) do
    self:initialize(player)
  end
  self.maid:Give(Players.PlayerAdded:Connect(function(player)
    self:initialize(player)
  end))
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    self.states[player] = nil
  end))
  return self
end

function RunStateService:destroy()
  self.maid:DoCleaning()
  self.states = {}
end

function RunStateService:initialize(player: Player)
  self.states[player] = {
    mode = "Adventure",
    startedAt = os.clock(),
    running = true,
    chapterStartedAt = {},
    chapterSplits = {},
  }
  player:SetAttribute("RunMode", "Adventure")
  player:SetAttribute("RunStarted", true)
  player:SetAttribute("RunCompleted", false)
end

function RunStateService:get(player: Player): RunState
  if not self.states[player] then
    self:initialize(player)
  end
  return self.states[player]
end

function RunStateService:setMode(player: Player, mode: string): boolean
  if mode ~= "Adventure" and mode ~= "TimeTrial" and mode ~= "Practice" then
    return false
  end
  local state = self:get(player)
  state.mode = mode
  state.startedAt = mode == "TimeTrial" and nil or os.clock()
  state.running = mode ~= "TimeTrial"
  state.completedAt = nil
  state.chapterStartedAt = {}
  state.chapterSplits = {}
  player:SetAttribute("RunMode", mode)
  player:SetAttribute("RunStarted", state.running)
  player:SetAttribute("RunCompleted", false)
  return true
end

function RunStateService:startAtGate(player: Player, gate: BasePart): boolean
  local state = self:get(player)
  if state.mode ~= "TimeTrial" or state.running then
    return false
  end
  local character = player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local root = character and character:FindFirstChild("HumanoidRootPart")
  if not humanoid or humanoid.Health <= 0 or not root or (root.Position - gate.Position).Magnitude > 12 then
    return false
  end
  state.startedAt = os.clock()
  state.running = true
  player:SetAttribute("RunStarted", true)
  return true
end

function RunStateService:onChapterReached(player: Player, stageIndex: number): (number?, boolean)
  if not RunRules.isValidStage(stageIndex, self.totalStages) then
    return nil, false
  end
  local state = self:get(player)
  if not state.running or not state.startedAt then
    return nil, false
  end
  local now = os.clock()
  if not state.chapterSplits[stageIndex] then
    state.chapterSplits[stageIndex] = now - (state.chapterStartedAt[stageIndex] or state.startedAt)
    state.chapterStartedAt[stageIndex + 1] = now
  end
  if stageIndex == self.totalStages and not state.completedAt then
    state.completedAt = os.clock()
    player:SetAttribute("RunCompleted", true)
    local elapsed = state.completedAt - state.startedAt
    if not RunRules.isEligibleCompletion(state.mode, elapsed, self.minimumTimeTrialSeconds) then
      return elapsed, false
    end
    return elapsed, true
  end
  return nil, false
end

function RunStateService:getElapsed(player: Player): number
  local state = self:get(player)
  if not state.startedAt then
    return 0
  end
  return (state.completedAt or os.clock()) - state.startedAt
end

return RunStateService
