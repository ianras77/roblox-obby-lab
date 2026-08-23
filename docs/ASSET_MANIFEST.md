# Asset manifest

Existing source references include hard-coded Roblox IDs in `GameConfig`, zone
configuration, checkpoint/key builders, and effects. They are unverified from
this Linux environment: asset existence, permissions, moderation status, and
ownership require Roblox Studio/Creator Hub verification.

No external art was uploaded by this work. Replace the current trial-and-error
music fallback with approved assets before publication; keep empty fallbacks so
missing audio cannot break gameplay.

`src/shared/Config/AssetRegistry.lua` is now the release gate for music. Every
entry must be marked both `verified` and `approvedForRelease` after ownership,
permission, moderation, and device playback checks. Unverified candidates are
intentionally skipped.
