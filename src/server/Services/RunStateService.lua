--!strict

local Players = game:GetService("Players")
local Maid = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("Maid"))

local RunStateService = {}
RunStateService.__index = RunStateService

export type RunState = {
  mode: string,
  startedAt: number,
  completedAt: number?,
  chapterStartedAt: { [number]: number },
  chapterSplits: { [number]: number },
}

function RunStateService.new(totalStages: number)
  local self = setmetatable({}, RunStateService)
  self.maid = Maid.new()
  self.totalStages = totalStages
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
    chapterStartedAt = {},
    chapterSplits = {},
  }
  player:SetAttribute("RunMode", "Adventure")
  player:SetAttribute("RunStarted", true)
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
  state.startedAt = os.clock()
  state.completedAt = nil
  state.chapterStartedAt = {}
  state.chapterSplits = {}
  player:SetAttribute("RunMode", mode)
  player:SetAttribute("RunStarted", true)
  return true
end

function RunStateService:onChapterReached(player: Player, stageIndex: number): (number?, boolean)
  local state = self:get(player)
  if not state.chapterStartedAt[stageIndex] then
    state.chapterStartedAt[stageIndex] = os.clock()
  end
  if stageIndex > 1 and not state.chapterSplits[stageIndex - 1] then
    state.chapterSplits[stageIndex - 1] = os.clock() - state.startedAt
  end
  if stageIndex == self.totalStages and not state.completedAt then
    state.completedAt = os.clock()
    player:SetAttribute("RunCompleted", true)
    if state.mode == "Practice" then
      return nil, false
    end
    return state.completedAt - state.startedAt, true
  end
  return nil, false
end

function RunStateService:getElapsed(player: Player): number
  local state = self:get(player)
  return (state.completedAt or os.clock()) - state.startedAt
end

return RunStateService
