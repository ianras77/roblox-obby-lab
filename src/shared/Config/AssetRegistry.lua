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
      key = "sparkle_particle",
      type = "ParticleTexture",
      id = "rbxassetid://260430117",
      verified = false,
      approvedForRelease = false,
      source = "legacy sparkle effects",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "soft_particle",
      type = "ParticleTexture",
      id = "rbxassetid://241594419",
      verified = false,
      approvedForRelease = false,
      source = "legacy ambient effects",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "leaf_particle",
      type = "ParticleTexture",
      id = "rbxassetid://484084159",
      verified = false,
      approvedForRelease = false,
      source = "legacy woodland effects",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "confetti_particle",
      type = "ParticleTexture",
      id = "rbxassetid://12824333",
      verified = false,
      approvedForRelease = false,
      source = "legacy finale effects",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "frog_decal",
      type = "Decal",
      id = "rbxassetid://148274626",
      verified = false,
      approvedForRelease = false,
      source = "legacy chapter decoration",
      note = "Verify ownership and moderation before release.",
    },
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
      key = "zone_1_ambience",
      type = "Sound",
      id = "rbxassetid://1846220524",
      verified = false,
      approvedForRelease = false,
      source = "legacy zone configuration",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "zone_2_ambience",
      type = "Sound",
      id = "rbxassetid://1837483576",
      verified = false,
      approvedForRelease = false,
      source = "legacy zone configuration",
      note = "Verify ownership and moderation before release.",
    },
    {
      key = "zone_3_ambience",
      type = "Sound",
      id = "rbxassetid://1837635151",
      verified = false,
      approvedForRelease = false,
      source = "legacy zone configuration",
      note = "Verify ownership and moderation before release.",
    },
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
