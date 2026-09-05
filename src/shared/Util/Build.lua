local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AssetRegistry"))
local SoundGroups = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("SoundGroups"))

local Build = {}
local PartProperties = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("PartProperties"))

local function applyAttributes(instance, attributes)
  if not attributes then
    return
  end
  for key, value in pairs(attributes) do
    instance:SetAttribute(key, value)
  end
end

function Build.tag(instance, tags)
  if tags then
    for _, tag in ipairs(tags) do
      CollectionService:AddTag(instance, tag)
    end
  end
end

function Build.part(props)
  local part = Instance.new("Part")
  part.Anchored = props.Anchored ~= false
  part.Size = props.Size or Vector3.new(10, 1, 10)
  part.CFrame = props.CFrame or CFrame.new()
  part.Color = props.Color or Color3.fromRGB(255, 255, 255)
  part.TopSurface = Enum.SurfaceType.Smooth
  part.BottomSurface = Enum.SurfaceType.Smooth
  part.Material = props.Material or Enum.Material.Plastic
  part.Name = props.Name or "Part"
  PartProperties.apply(part, props, game:GetService("RunService"):IsStudio())
  applyAttributes(part, props.Attributes)
  Build.tag(part, props.Tags)
  part.Parent = props.Parent
  return part
end

function Build.model(name, parent)
  local model = Instance.new("Model")
  model.Name = name
  model.Parent = parent
  return model
end

function Build.checkpoint(name, cframe, size, parent)
  local cp = Build.part({
    Name = name,
    CFrame = cframe,
    Size = size,
    Color = Color3.fromRGB(255, 255, 0),
    Parent = parent,
    Material = Enum.Material.Neon,
    Tags = { "Checkpoint" },
  })

  local glow = Instance.new("PointLight")
  glow.Range = 22
  glow.Brightness = 3.8
  glow.Color = Color3.fromRGB(255, 230, 150)
  glow.Parent = cp

  local ring = Build.part({
    Name = "CheckpointRing",
    Parent = cp,
    CFrame = cframe * CFrame.new(0, 0.6, 0),
    Size = Vector3.new(size.X * 1.1, 0.3, size.Z * 1.1),
    Color = Color3.fromRGB(255, 220, 140),
    Material = Enum.Material.Neon,
  })
  ring.Anchored = true
  ring.CanCollide = false

  local gui = Instance.new("BillboardGui")
  gui.Size = UDim2.fromOffset(120, 40)
  gui.AlwaysOnTop = true
  gui.Adornee = cp
  gui.Parent = cp

  local text = Instance.new("TextLabel")
  text.Size = UDim2.fromScale(1, 1)
  text.BackgroundTransparency = 1
  text.Text = cp.Name
  text.Font = Enum.Font.GothamBold
  text.TextScaled = true
  text.TextColor3 = Color3.new(1, 1, 1)
  text.Parent = gui

  local sound = Instance.new("Sound")
  sound.SoundId = AssetRegistry.getApprovedId("checkpoint_feedback")
  sound.Volume = 0.4
  sound.SoundGroup = SoundGroups.ensure("SFX", 0.8)
  sound.Parent = cp

  local burst = Instance.new("ParticleEmitter")
  burst.Name = "CheckpointBurst"
  burst.Texture = AssetRegistry.getApprovedId("soft_particle")
  burst.Lifetime = NumberRange.new(0.6, 0.9)
  burst.Speed = NumberRange.new(8, 12)
  burst.Rate = 0
  burst.Parent = cp

  return cp
end

function Build.collectibleKey(cframe, parent)
  local key = Build.part({
    Name = "GoldenKey",
    Parent = parent,
    CFrame = cframe,
    Size = Vector3.new(1.5, 3, 0.5),
    Color = Color3.fromRGB(255, 215, 0),
    Material = Enum.Material.Neon,
    Tags = { "KeyCollectible", "VisualBob" },
    CanCollide = false,
    Anchored = true,
  })
  local spark = Instance.new("ParticleEmitter")
  spark.Texture = AssetRegistry.getApprovedId("soft_particle")
  spark.Lifetime = NumberRange.new(0.6, 1)
  spark.Speed = NumberRange.new(4, 7)
  spark.Rate = 0
  spark.Parent = key

  local sound = Instance.new("Sound")
  sound.SoundId = AssetRegistry.getApprovedId("key_pickup")
  sound.Volume = 0.6
  sound.SoundGroup = SoundGroups.ensure("SFX", 0.8)
  sound.Parent = key

  return key
end

function Build.cart(cframe, parent, rideMaxDistance)
  local model = Build.model("ToadCart", parent)
  local base = Build.part({
    Name = "CartBase",
    Parent = model,
    Size = Vector3.new(6, 1, 8),
    CFrame = cframe,
    Color = Color3.fromRGB(80, 60, 40),
    Material = Enum.Material.Wood,
    Anchored = false,
    Tags = { "Cart" },
    Attributes = { RideMaxDistance = rideMaxDistance or 68 },
  })
  local seat = Instance.new("Seat")
  seat.Name = "Seat"
  seat.Size = Vector3.new(2, 1, 2)
  seat.CFrame = cframe * CFrame.new(0, 1.25, 0)
  seat.Anchored = false
  seat.Parent = model

  local weld = Instance.new("WeldConstraint")
  weld.Part0 = base
  weld.Part1 = seat
  weld.Parent = model

  local attachment = Instance.new("Attachment")
  attachment.Parent = base

  local vel = Instance.new("LinearVelocity")
  vel.MaxForce = 4000
  vel.VectorVelocity = cframe.RightVector * 8
  vel.Attachment0 = attachment
  vel.Parent = base

  local gyro = Instance.new("AlignOrientation")
  gyro.MaxTorque = 5000
  gyro.Responsiveness = 20
  gyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
  gyro.Attachment0 = attachment
  gyro.Parent = base

  model:MoveTo(cframe.Position)
  return model
end

return Build
