local controllers = script.Parent:WaitForChild("Controllers")
local UIController = require(controllers:WaitForChild("UIController"))
local EffectsController = require(controllers:WaitForChild("EffectsController"))

UIController.new()
EffectsController.new()
