# Kid-friendly route review — 2026-11-16

## Revision and scope

This review starts from `codex/production-playability` at
`ba7b8950871c130f6d00dcd979f907be037c09fb`, not the older default branch.
`main` was `b0af18b1ab0cd819b5d1f0537476a22aa22e3046`; draft PR #1's
branch was `e8cd5c484cb6dd606386966fa1dd3b541e445968`. All three were rechecked
before publishing this separate review branch. No AGENTS.md or .agents skills
were present in this repository or its workspace ancestors. No existing branch
was rewritten. This draft is based on the production-playability branch so its
diff isolates this review while retaining the preceding work.

## Confirmed findings and changes

| Area | Finding | Change / evidence |
| --- | --- | --- |
| Opening the game | Both tracked place exports embed obsolete source. Opening them bypasses newer fixes. | Remove stale exports. Build from current source; CI uploads production and isolated harness places labelled by commit. |
| Raised zones | The 4-stud rise over a 16-stud center-to-center connector runs under the next 14-stud landing, leaving a collision lip. Floor support tests alone accept it. | 48-stud transitions; ramps connect landing edges with 34-stud horizontal run (slope 4/34, about 6.7 degrees). Sampled overhead-clearance tests cover both boundaries. |
| Failed jumps | Catch floor was 4 studs below pads, with one recovery ramp beneath pads and a rail obstructing the near-side exit. | 2-stud drop, three 14-stud-wide recovery ramps reaching landing edges; rails moved to catch-deck boundaries. Missing-ramp mutation fails even with catch floor below. |
| Terrain / mountains | Rojo source sync does not clear imported terrain. Validator included only generated floor geometry. | Clear terrain only in the reserved play-session corridor: X -24..2104, Y -7..77, Z -48..64 for the current config. No Terrain:Clear. Check actual Workspace for sampled overhead obstruction, excluding player characters during rebuild. Imported solid parts are retained and named in errors. |
| Spawn / respawn | Identity CFrames face -Z while the course travels +X; replay spawn also faced away from its bridge. | Checkpoints, new joins and practice face +X; replay spawn faces +Z down the bridge. Regression checks directions and resets velocity. Release seated players on teleport. |
| Movement budget | Avatar/place defaults could vary the movement assumed by authored route tests. | Set WalkSpeed 16, UseJumpPower false, JumpHeight 7.2 and mobile auto-jump on each character. Required flat gaps remain only 2 studs (0 on relief chapters), with 14-stud landings. |
| Navigation / visibility | Unlimited AlwaysOnTop chapter banners stack across the whole map; zone tinting muddies checkpoints, keys and optional-lane colors. | Distance-limit signs to 100–130 studs, keep semantic colors, label the final checkpoint as home/replay rather than another chapter. |
| CI / tests | CI ran Lune without installing it; headless script lacked its executable bit. | Pin/install Lune 0.10.4; make script executable; upload revision-labelled places. |
| Test fidelity | Pinned Lune returns different userdata handles for the same Instance, and its lookAt result mirrored +Z in a direct probe. | Cache proxies by GetDebugId. Construct connector bases explicitly. Analytic rays support exclusion filters and cache geometry; terrain is explicitly not simulated. |

## Full-route assessment

All 18 chapters use the retained broad required spine. Seven stable landings per
chapter, gentle flat gaps, connected optional lanes, personal collectibles and
checkpoints remain intact. Stages 6/7 and 12/13 are the two raised transitions.
The final exit has the existing replay deck. Optional bounce pads, movers,
sweepers, timed hazards, conveyor, cart and wind remain optional; a novice can
finish without keys, purchases, cooperation or accepting a skip.

The intended difficulty is forgiving Adventure play. The catch deck makes small
misses recoverable; wider platform spacing between *zones* adds walking distance,
not a longer required jump. No maximum jump is required. Repeated recovery ramps
reduce backtracking. Optional lessons retain some variety, but much of the main
route repeats the same stepping-stone pattern: children's enjoyment and whether
they find it too repetitive still need direct observation. Authored novice-time
estimates are hypotheses, not measured completion times.

Multiplayer ownership, monotonic sequential checkpoint progression, independent
keys, personal finale events, rebuild/session retention and player collision
groups were inspected and retained. Headless tests exercise 1, 2 and 8 simulated
players, delayed roots, duplicate/backward checkpoints, reset/fall/help, seated
recovery, replay start, late joins, rebuild, character replacement and cleanup.
These are server logic checks, not Roblox replication or contact-physics evidence.

## Validation and its limits

Tools: Luau 0.734, StyLua 2.3.1, Rojo 7.4.4, Lune 0.10.4, Selene 0.29.0.

- Campaign/route mutations, movement/assist, Build properties, hazard activation,
  config, profile, progression, run rules and asset suites pass.
- StyLua and git diff whitespace checks pass.
- Production and isolated Studio-harness Rojo builds pass.
- Headless production generation/validation passes for all 18 stages. Negative
  tests reject missing pads, missing recovery ramps, external mountains between
  route nodes, overhead ceilings, wrong respawn direction and controller conflicts.
- All 1/2/8-player headless lifecycle scenarios pass. Terrain tests verify only
  the bounded FillBlock request; no terrain voxels are simulated.
- Local Selene is blocked fetching its Roblox API dump: its HTTP client fails DNS
  in this execution environment. The full check.sh therefore stops at lint locally;
  pure tests and format checks before that step passed. Hosted CI is the remaining
  lint check; its actual result is reported on the draft PR.

No Roblox Studio binary was available in the Linux execution environment. No
engine playtest, render, mobile/gamepad, real multiplayer, network emulation,
performance or child playtest was performed. Neither Rojo packaging nor analytic
rays establish real in-engine playability. Clearance rays are sampled (2-stud
spacing), not continuous swept-avatar collision proofs. Imported non-collidable
visual scenery and camera composition still require visual inspection.

## Reproducible Studio acceptance test

1. Check out the draft revision. Run `rojo build default.project.json -o obby-current.rbxlx`.
   Open that fresh file in Studio; leave the DataStore environment at StudioDevelopment.
   Press Play, verify Output reports 18 stages and has no validator/runtime errors.
2. Walk/jump through **every** chapter without developer teleport or Help. Record
   stage, device, avatar and failure cause. Check 6→7 and 12→13 ramps in both
   directions at walk speed, including near both edges. No lip, trap or required
   maximum-distance jump is acceptable.
3. Deliberately miss the first, middle and last small gap in each chapter. Walk
   to a near-side ramp and recover without Reset; check low ceilings and rails.
   Fall entirely off each zone and verify prompt recovery at the last checkpoint,
   zero residual velocity, safe footing and forward orientation. Reset from the cart.
4. Test every optional lane. Wait through complete hazard cycles; confirm warning
   vs active states, mover boarding, cart exit/reset, bounce landings and wind
   steering. Confirm a new player can ignore all detours and still finish.
5. In a **disposable Studio copy**, before Play create terrain rock/water across
   the course at X=40 and at each raised transition. Start Play; the reserved
   corridor must be empty and distant terrain preserved. Stop Play and verify
   edit-mode terrain remains. Insert a solid Part wall between route nodes in a
   separate test: startup must name the obstructing part rather than accept it.
   Remove it before continuing. Inspect camera views for distant hills/scenery.
6. Use Studio Server & Clients with two players: arrive at the same checkpoint,
   collect the same key independently, bump/pass each other, reset while the other
   moves, finish one player only, rejoin, and rebuild. Verify no stolen keys,
   accidental pushes, progression skips or other-player finale. Repeat with 8
   clients if feasible; inspect Output and frame/server performance.
7. Repeat a complete run using mobile emulation and a gamepad, with small/large
   supported R6/R15 avatars. Check thumbstick partial-speed jumps, sign readability,
   checkpoint visibility, reduced-motion/high-contrast settings, HUD safe areas,
   and menu controls after the finale.
8. For the existing integration harness, build
   `rojo build studio-test.project.json -o obby-studio-tests.rbxlx`, start clients,
   then run `require(game.ServerStorage.PlayabilityHarness).run()` from the server
   command bar. This teleports between checkpoints; it does not replace steps 2–7.
9. Have the children complete an unprompted run. Record where they hesitate,
   request help, repeatedly fail or lose interest. Keep the PR draft until
   physical traversal and the enjoyment/navigation goals have been checked.

Roblox API references: [Humanoid movement](https://create.roblox.com/docs/reference/engine/classes/Humanoid),
[Terrain FillBlock](https://create.roblox.com/docs/reference/engine/classes/Terrain#FillBlock),
[raycasting](https://create.roblox.com/docs/workspace/raycasting).
