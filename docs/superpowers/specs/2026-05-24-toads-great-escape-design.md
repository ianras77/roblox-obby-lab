# Toad's Great Escape Obby Design

## Goal

Turn the existing procedural obby into a playable, kid-friendly homage to the public-domain book world of riverbanks, Toad Hall, motorcar trouble, court/jail chaos, Wild Wood, and a triumphant homecoming. The game should feel like a bright storybook adventure children can play first, then remix by changing obvious config knobs and stage templates.

## Story

The player arrives at the riverbank for a calm visit, but Toad announces one more brilliant idea. The visit becomes a runaway chapter tour:

1. Riverbank Welcome
2. Mole's Burrow Bounce
3. Ratty's River Stones
4. Toad Hall Gate
5. Library Tumble
6. Runaway Caravan
7. Tavern Barrel Hop
8. Courtroom Chaos
9. Jailbreak Bars
10. Laundry Cart Escape
11. Barge Crossing
12. Train Tunnel Dash
13. Wild Wood Gusts
14. Badger's Lantern Path
15. Motorcar Madness
16. Roadside Cone Sprint
17. Homecoming Ring Run
18. Toad Hall Fireworks

The tone is original and book-inspired, avoiding direct theme-park references.

## Architecture

Keep the Rojo project and runtime world generation intact. The main changes live in `WorldGenConfig.lua`, `ZoneConfig.lua`, `StageTemplates.lua`, `StageBuilder.lua`, `DecorBuilder.lua`, `UIController.lua`, and the kid docs. `WorldBuilder`, `ObbyService`, and `CheckpointService` should remain structurally the same unless a playability issue is found.

## Gameplay Requirements

- Generate exactly 18 stages by default.
- Give every stage a clear story name and a visible checkpoint banner.
- Preserve a simple forward path; no hidden routes required to finish.
- Mix easy wins with motion, bounce, conveyors, timed obstacles, lasers, falling platforms, wind, and finale effects.
- Use bright, readable, child-friendly colors and short signs.
- Keep the project deterministic by seed.
- Make the kid hack points obvious in README and config comments.

## Testing

Add a lightweight Bash repository test that validates the storyboard contract statically:

- `WorldGenConfig.StageTypes` has 18 entries.
- Every configured stage type has a matching `StageTemplates.<Name>` function.
- The game title appears in `GameConfig`.
- Kid docs reference the new book-homage theme.

Continue using `scripts/check.sh` for style/lint verification.
