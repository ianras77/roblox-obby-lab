--!strict

local CollectionService = game:GetService("CollectionService")

local WorldValidator = {}

function WorldValidator.validate(stages: { any }, totalStages: number): ({ string }, number)
  local errors = {}
  local ids = {}
  local checkpoints = {}
  for _, stage in ipairs(stages) do
    if stage.stageIndex ~= #checkpoints + 1 then
      table.insert(errors, string.format("stage order gap or duplicate near %d", stage.stageIndex or -1))
    end
    if not stage.stageId then
      table.insert(errors, "stage missing stable stageId")
    elseif ids[stage.stageId] then
      table.insert(errors, "duplicate stage id: " .. stage.stageId)
    else
      ids[stage.stageId] = true
    end
    if not stage.checkpoint or not stage.checkpoint:IsA("BasePart") then
      table.insert(errors, string.format("stage %d missing checkpoint", stage.stageIndex or -1))
    else
      checkpoints[stage.stageIndex] = true
      if stage.checkpoint:GetAttribute("StageIndex") ~= stage.stageIndex then
        table.insert(errors, string.format("checkpoint %d has wrong stage index", stage.stageIndex))
      end
    end
    if not stage.entrance or not stage.exit then
      table.insert(errors, string.format("stage %d missing entrance or exit", stage.stageIndex or -1))
    end
    if not stage.model:GetAttribute("PrimaryMechanic") then
      table.insert(errors, string.format("stage %d missing presentation metadata", stage.stageIndex or -1))
    end
  end
  for index = 1, totalStages do
    if not checkpoints[index] then
      table.insert(errors, "missing checkpoint for stage " .. index)
    end
  end
  for _, key in ipairs(CollectionService:GetTagged("KeyCollectible")) do
    if not key:GetAttribute("KeyId") then
      table.insert(errors, "collectible missing KeyId: " .. key:GetFullName())
    end
  end
  return errors, #stages
end

return WorldValidator
