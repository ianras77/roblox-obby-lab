# README_KIDS - Quick Hacks for Toad's Great Escape

This is a kid-safe homage to **The Wind in the Willows**: riverbank friends, Toad Hall, runaway vehicles, court trouble, jail escape, Wild Wood, and a happy homecoming.

1. **New seed, new storybook route**
   - Open `src/shared/Config/GameConfig.lua` and change `Seed`. Run `/rebuild` in Studio to see a new layout.
2. **Change the chapter order**
   - Open `src/shared/Config/WorldGenConfig.lua` and move names around inside `StageTypes`.
3. **Make Toad's road faster**
   - In `src/shared/Config/ObstacleConfig.lua`, raise `ConveyorSpeed` for runaway roads and caravans.
4. **Make the bounce chapters sillier**
   - In `ObstacleConfig.lua`, raise `BouncePower`, then try Mole's Burrow Bounce again.
5. **Repaint the world**
   - Open `src/shared/Config/ZoneConfig.lua` and change `ThemeColor` for each zone.
6. **Write your own sign jokes**
   - Open `src/server/WorldGen/Templates/StageTemplates.lua`, search for `addSign`, and change the words.
7. **Add a new chapter**
   - Add a name to `StageTypes`, then create a matching `function StageTemplates.YourName(ctx)` in `StageTemplates.lua`.

Tip: Use `/reseed 9999` to lock in a favorite layout and share the seed with friends.
