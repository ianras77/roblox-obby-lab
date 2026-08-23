# Asset manifest

Existing source references include hard-coded Roblox IDs in `GameConfig`, zone
configuration, checkpoint/key builders, and effects. They are unverified from
this Linux environment: asset existence, permissions, moderation status, and
ownership require Roblox Studio/Creator Hub verification.

Current referenced IDs (all unverified):

| ID | Type | Source/use |
| --- | --- | --- |
| `1846220524` | Sound | Zone 1 ambience |
| `1837483576` | Sound | Zone 2 ambience |
| `1837635151` | Sound | Zone 3 ambience |
| `1843521234` | Sound | Legacy riverbank music candidate |
| `1837468655` | Sound | Legacy trouble music candidate |
| `12222152` | Sound | Checkpoint feedback |
| `12222058` | Sound | Key pickup |

## Local source art

| Path | Purpose | Dimensions/viewBox | Status | Roblox upload action |
| --- | --- | --- | --- | --- |
| `art/branding/toads-great-escape-logo.svg` | Experience branding and title card | 1200 x 420 | Source-ready, not uploaded | Export/upload approved PNG variants for icon, thumbnail, and UI use |
| `art/ui/golden-key.svg` | Golden Key HUD and collectible reference | 256 x 256 | Source-ready, not uploaded | Export/upload transparent PNG if a Roblox image ID is required |

These files are original local vector sources. No Roblox asset IDs are claimed
for them until an owner uploads and verifies the resulting assets in Creator
Hub/Studio.
| `241594419` | Particle texture | Spark/burst effects |
| `260430117` | Particle texture | Sparkle/firefly effects |
| `258128463` | Particle texture | Impact/firework effects |
| `484084159` | Particle texture | Woodland leaves |
| `12824333` | Particle texture | Confetti |
| `148274626` | Decal | Legacy frog sign |
| `138186576` | Sound | Client impact effect |

No external art was uploaded by this work. Replace the current trial-and-error
music fallback with approved assets before publication; keep empty fallbacks so
missing audio cannot break gameplay.

Source-art briefs are stored in `art/prompts/`. No raster output is claimed
until the image-generation workflow is available and each final file is
reviewed for originality, dimensions, and intended Roblox use.

`src/shared/Config/AssetRegistry.lua` is now the release gate for music. Every
entry must be marked both `verified` and `approvedForRelease` after ownership,
permission, moderation, and device playback checks. Unverified candidates are
intentionally skipped.
