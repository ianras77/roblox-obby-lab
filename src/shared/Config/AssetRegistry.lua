--!strict

export type AssetDefinition = {
  key: string,
  type: string,
  id: string,
  verified: boolean,
  approvedForRelease: boolean,
  source: string,
  note: string,
}

-- IDs remain visible for auditability, but unverified assets are not selected
-- by production code. Replace verified=false only after Creator Hub review.
local registry = {
  effects = {
    {
      key = "checkpoint_feedback",
      type = "Sound",
      id = "rbxassetid://12222152",
      verified = false,
      approvedForRelease = false,
      source = "legacy checkpoint builder",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "key_pickup",
      type = "Sound",
      id = "rbxassetid://12222058",
      verified = false,
      approvedForRelease = false,
      source = "legacy collectible builder",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "finale_firework",
      type = "ParticleTexture",
      id = "rbxassetid://258128463",
      verified = false,
      approvedForRelease = false,
      source = "legacy finale effect",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "finale_chime",
      type = "Sound",
      id = "rbxassetid://138186576",
      verified = false,
      approvedForRelease = false,
      source = "legacy finale effect",
      note = "Verify ownership and moderation before release.",
    },
  },
  music = {
    {
      key = "riverbank_theme",
      type = "Sound",
      id = "rbxassetid://1843521234",
      verified = false,
      approvedForRelease = false,
      source = "legacy GameConfig candidate",
      note = "Must be checked for ownership, permission, and content.",
    },
    {
      key = "trouble_motif",
      type = "Sound",
      id = "rbxassetid://1837468655",
      verified = false,
      approvedForRelease = false,
      source = "legacy GameConfig candidate",
      note = "Must be checked for ownership, permission, and content.",
    },
  },
}

function registry.getApprovedId(key: string): string
  for _, group in ipairs({ registry.effects, registry.music }) do
    for _, asset in ipairs(group) do
      if asset.key == key and asset.verified and asset.approvedForRelease then
        return asset.id
      end
    end
  end
  return ""
end

return registry
