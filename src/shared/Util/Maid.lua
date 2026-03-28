local Maid = {}
Maid.__index = Maid

function Maid.new()
  local self = setmetatable({}, Maid)
  self.tasks = {}
  return self
end

function Maid:Give(task)
  table.insert(self.tasks, task)
  return task
end

function Maid:DoCleaning()
  for i = #self.tasks, 1, -1 do
    local task = self.tasks[i]
    if typeof(task) == "RBXScriptConnection" then
      task:Disconnect()
    elseif typeof(task) == "function" then
      task()
    elseif typeof(task) == "Instance" then
      task:Destroy()
    end
    self.tasks[i] = nil
  end
end

return Maid
