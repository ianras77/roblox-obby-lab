-- Canonical templates use the validated authored route. Legacy experiments are not required here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Definitions = require(ReplicatedStorage.Config.StageDefinitions)
local RouteBuilder = require(script.Parent.Parent.RouteBuilder)
local StageTemplates = {}
for _, definition in ipairs(Definitions) do
  StageTemplates[definition.canonicalName] = function(ctx)
    return RouteBuilder.stage(ctx, definition)
  end
end
return StageTemplates
