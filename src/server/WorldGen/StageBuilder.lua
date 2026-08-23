local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageTemplates = require(script.Parent:WaitForChild("Templates"):WaitForChild("StageTemplates"))
local Build = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Build"))
local WorldGenConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldGenConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local StageConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("StageConfig"))
local ChapterConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ChapterConfig"))

local StageBuilder = {}

export type StageBuildResult = {
  model: Model,
  entrance: CFrame,
  exit: CFrame,
  checkpoint: BasePart,
  safeSpawn: CFrame,
  bounds: Vector3,
  mechanics: { string },
  pathCorridor: {
    center: CFrame,
    width: number,
  },
}

function StageBuilder.buildStage(args)
  local stageType = args.stageType
  local template = StageTemplates[stageType]
  if not template then
    error(string.format("No stage template registered for %s", tostring(stageType)))
  end

  local model = Instance.new("Model")
  model.Name = string.format("Stage_%02d_%s", args.stageIndex, stageType)
  model.Parent = args.parent

  local totalStages = GameConfig.Zones * GameConfig.StagesPerZone
  local displayName = WorldGenConfig.StageDisplayNames[stageType] or stageType
  local difficulty = math.clamp(args.stageIndex / math.max(1, totalStages), 0, 1)

  local builtModel, endCFrame = template({
    parent = model,
    origin = args.origin,
    color = args.zoneColor,
    difficulty = difficulty,
    stageIndex = args.stageIndex,
    random = args.random,
  })

  if not builtModel or not builtModel:IsA("Model") then
    error(string.format("Stage template %s returned a non-model", stageType))
  end
  if builtModel ~= model then
    builtModel.Parent = model
  end

  if typeof(endCFrame) ~= "CFrame" then
    error(string.format("Stage template %s did not return a valid exit CFrame", stageType))
  end
  local definition = StageConfig.getByIndex(args.stageIndex)
  local stageId = definition and definition.id or string.format("stage_%03d", args.stageIndex)
  local presentation = ChapterConfig[stageType]
  if not presentation then
    error(string.format("No chapter presentation metadata registered for %s", stageType))
  end
  model:SetAttribute("StageId", stageId)
  model:SetAttribute("StageIndex", args.stageIndex)
  model:SetAttribute("ChapterName", displayName)
  model:SetAttribute("ChapterFlavor", presentation.flavor)
  model:SetAttribute("PrimaryMechanic", presentation.mechanic)
  model:SetAttribute("DifficultyTier", presentation.tier)

  local checkpointCFrame = endCFrame * CFrame.new(0, WorldGenConfig.PlatformSize.Y + 2, 0)
  local cp =
    Build.checkpoint(string.format("CP_%03d", args.stageIndex), checkpointCFrame, WorldGenConfig.CheckpointSize, model)
  cp:SetAttribute("StageId", stageId)
  cp:SetAttribute("StageIndex", args.stageIndex)

  -- Floating stage banner visible from afar
  local banner = Instance.new("BillboardGui")
  banner.Size = UDim2.fromOffset(280, 120)
  banner.StudsOffset = Vector3.new(0, 14, 0)
  banner.AlwaysOnTop = true
  banner.Adornee = cp
  banner.Parent = model

  local bannerText = Instance.new("TextLabel")
  bannerText.BackgroundTransparency = 0.15
  bannerText.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
  bannerText.BorderSizePixel = 0
  bannerText.Text = string.format("Stage %d / %d: %s", args.stageIndex, totalStages, displayName)
  bannerText.Font = Enum.Font.GothamBlack
  bannerText.TextScaled = true
  bannerText.TextColor3 = Color3.fromRGB(255, 230, 180)
  bannerText.Parent = banner

  -- Directional arrow to keep players moving forward
  local arrow = Instance.new("BillboardGui")
  arrow.Size = UDim2.fromOffset(200, 80)
  arrow.StudsOffset = Vector3.new(0, 8, 0)
  arrow.AlwaysOnTop = true
  arrow.Adornee = cp
  arrow.Parent = model
  local arrowLabel = Instance.new("TextLabel")
  arrowLabel.BackgroundTransparency = 1
  arrowLabel.Text = ">> NEXT CHAPTER >>"
  arrowLabel.Font = Enum.Font.GothamBlack
  arrowLabel.TextScaled = true
  arrowLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
  arrowLabel.Parent = arrow

  -- One deliberate exploration key per chapter; keys never gate the required route.
  if GameConfig.AuthoredKeysPerChapter > 0 then
    -- Keep the collectible route authored and reproducible. Decorative seed
    -- variation must not move a progression-adjacent key into an accidental
    -- hazard or change its intended exploration lane.
    local keyOffset = ((args.stageIndex - 1) % 3 - 1) * 6
    local key = Build.collectibleKey(args.origin * CFrame.new(10, 6, keyOffset), model)
    key:SetAttribute("KeyId", string.format("%s_key_01", stageId))
    key:SetAttribute("StageIndex", args.stageIndex)
  end

  -- Optional cart at start of some stages
  if args.stageIndex % 3 == 0 then
    Build.cart(args.origin * CFrame.new(-4, 1.5, 0), model)
  end

  local _, bounds = model:GetBoundingBox()
  return {
    model = model,
    entrance = args.origin,
    exit = endCFrame,
    checkpoint = cp,
    safeSpawn = cp.CFrame + Vector3.new(0, 4, 0),
    bounds = bounds,
    mechanics = { presentation.mechanic },
    pathCorridor = {
      center = args.origin,
      width = WorldGenConfig.PathWidth,
    },
  } :: StageBuildResult
end

return StageBuilder
