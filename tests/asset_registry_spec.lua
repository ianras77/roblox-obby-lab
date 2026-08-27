--!strict
-- selene: allow(incorrect_standard_library_use)

local AssetRegistry = require("../src/shared/Config/AssetRegistry")

local function expect(condition: boolean, message: string)
  assert(condition, message)
end

expect(AssetRegistry.getApprovedId("does_not_exist") == "", "unknown assets fail closed")

local keys = {}
for _, group in ipairs({ AssetRegistry.effects, AssetRegistry.music }) do
  for _, asset in ipairs(group) do
    expect(type(asset.key) == "string" and asset.key ~= "", "asset key is required")
    expect(not keys[asset.key], "asset keys are unique")
    keys[asset.key] = true
    expect(type(asset.type) == "string" and asset.type ~= "", "asset type is required")
    expect(type(asset.source) == "string" and asset.source ~= "", "asset source is required")
    expect(type(asset.note) == "string" and asset.note ~= "", "asset note is required")
    expect(type(asset.id) == "string" and asset.id:match("^rbxassetid://%d+$") ~= nil, "asset ID format is valid")
    if not (asset.verified and asset.approvedForRelease) then
      expect(AssetRegistry.getApprovedId(asset.key) == "", "unapproved asset is not selectable")
    end
  end
end

print("asset registry tests passed")
