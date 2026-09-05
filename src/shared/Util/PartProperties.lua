--!strict
-- Build.part applies these before parenting. Parent, Tags, Attributes are metadata.
local PartProperties = {
  Anchored = true,
  Size = true,
  CFrame = true,
  Color = true,
  Material = true,
  Name = true,
  Transparency = true,
  CanCollide = true,
  CanTouch = true,
  CanQuery = true,
  Shape = true,
  CastShadow = true,
  Massless = true,
  CollisionGroup = true,
}

function PartProperties.apply(target, props, strict)
  for key, value in pairs(props) do
    if PartProperties[key] == true then
      target[key] = value
    elseif key ~= "Parent" and key ~= "Attributes" and key ~= "Tags" and strict then
      error("Build.part unsupported property: " .. tostring(key))
    end
  end
end
return PartProperties
