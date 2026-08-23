local controllers = script.Parent:WaitForChild("Controllers")
local UIController = require(controllers:WaitForChild("UIController"))
local EffectsController = require(controllers:WaitForChild("EffectsController"))
local EnvironmentController = require(controllers:WaitForChild("EnvironmentController"))

UIController.new()
EffectsController.new()
EnvironmentController.new()
