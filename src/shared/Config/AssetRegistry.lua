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
return {
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
