# README_KIDS — Quick Hacks (Mr. Toad Edition)

1) **New seed, new ride**
   - Open `src/shared/Config/GameConfig.lua` and change `Seed`. Run `/rebuild` in Studio to see a brand-new Toad adventure.
2) **Speed up the runaway caravans**
   - In `src/shared/Config/ObstacleConfig.lua`, boost `ConveyorSpeed` to make the Caravan Chase go wild.
3) **Faster blinking lasers**
   - In `ObstacleConfig.lua`, lower `LaserCycleTime` (e.g., 1.5) to make Courtroom Chaos harder.
4) **Make boats bouncy**
   - In `ObstacleConfig.lua`, raise `MovingPlatformSpeed` so River Barge boats sway faster.
5) **Add your own set-piece**
   - Append a name to `StageTypes` in `src/shared/Config/WorldGenConfig.lua`, then create a matching function in `src/server/WorldGen/Templates/StageTemplates.lua` (copy one and remix).

Tip: Use `/reseed 9999` to lock in a favorite layout and share the seed with friends.
