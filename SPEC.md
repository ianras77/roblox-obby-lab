# CODEX PROGRAM 2 (REVISED) — "OBBY OF LEGENDS: Fully Procedural, Environment-Built"

## Mission
Create an insane obby that is generated entirely by code at runtime.
NO manual geometry creation required. The server builds everything into Workspace.

## High-level behavior
On server startup:
- Clear any old Workspace/Obby
- Generate Zones and Stages using a deterministic seed
- Create platforms, hazards, decorations, checkpoints
- Apply CollectionService tags + attributes
- Start obstacle behaviors (moving, rotating, timed, lasers, conveyors, bounce, wind)
- Provide a dev command to rebuild the whole world instantly

## Determinism
- Use a seed stored in GameConfig.
- Same seed = same obby layout.
- Allow /reseed <number> for dev (Studio only / allowlist).

## Repo structure (add these)
src/
  shared/
    Config/
      GameConfig.lua
      ZoneConfig.lua
      ObstacleConfig.lua
      WorldGenConfig.lua
    Util/
      Maid.lua
      Math.lua
      Random.lua (seeded RNG wrapper)
      Build.lua (helpers to create Parts/Models quickly)
  server/
    WorldGen/
      WorldBuilder.lua
      ZoneBuilder.lua
      StageBuilder.lua
      DecorBuilder.lua
      Templates/
        StageTemplates.lua
        ObstacleTemplates.lua
    Services/
      CheckpointService.lua
      ObbyService.lua
      DataStoreServiceWrapper.lua
    ServerMain.server.lua
  client/
    Controllers/
      UIController.lua
      EffectsController.lua
    ClientMain.client.lua

## World layout rules
- Generate N zones (default 3), each with M stages (default 6) => 18 stages
- Stages connect in a single forward path (simple to understand)
- Each stage is 40–60 studs apart along X
- Each zone shifts elevation and theme color

## Stage types (must implement at least these 10)
1) Warmup jumps (static)
2) Moving platforms (sine path)
3) Rotating sweeper beams
4) Disappearing tiles (timed)
5) Conveyor + gaps
6) Bounce pad sequence
7) Lava rising corridor (slow, forgiving)
8) Wind tunnel sideways push
9) Laser grid with shifting safe lanes
10) “Finale ring run” with fireworks at end

## Checkpoints
- After every stage place a checkpoint part CP_### with billboard + sound
- Touch sets respawn CFrame
- Save highest CP reached (DataStore wrapper; mock in Studio via config)

## Obstacle behavior system
- All obstacles are models created by the generator
- Add CollectionService tags: "MovingPlatform", "Rotator", "Laser", "Conveyor", "TimedTile", "BouncePad", "WindZone", "KillBrick"
- ObbyService scans tags and attaches behavior controllers (server-driven for physics, client-driven for VFX only)

## Lighting + polish (from code)
- Create Lighting objects: Atmosphere, BloomEffect, ColorCorrectionEffect
- Set each zone’s ambient color palette
- Add particle emitters for “wow” moments (safe performance defaults)
- Add a simple music loop hook (no copyrighted audio; placeholder only)

## UI
- Progress bar: stage / total
- Big Reset button
- Optional Skip Stage (off by default)
- Tooltip prompts in early stages: “Try changing WorldGenConfig.PLATFORM_SPEED!”

## Dev tools
- /rebuild (rebuild world using current seed)
- /reseed 12345 (set seed and rebuild)
- /stage 12 (teleport to checkpoint stage)
Allowlist userIds in GameConfig; commands only in Studio or private server mode.

## Required docs
- README.md: how to run Rojo + Studio bridge
- README_KIDS.md: 5 “kid hacks”
  - Change seed
  - Increase platform speed
  - Make lasers faster
  - Add a new stage type
  - Change zone colors

## Acceptance criteria
- With no manual building, pressing Play creates a complete obby in Workspace
- Minimum 18 stages with checkpoints
- At least 6 obstacle behaviors running
- Reset + progress UI works
- /rebuild and /stage works for allowlist
- Server prints a summary: zones/stages/obstacles count and seed

## Output rules
- Generate all files with full code contents.
- Prefer robust, beginner-readable Luau.
- Add "Kid Notes" comments near the config knobs.
