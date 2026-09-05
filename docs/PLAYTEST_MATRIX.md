# Playtest matrix

Status as of 2026-09-05: **all Studio/device/network/performance/human rows outstanding**. Local executable tests are recorded separately in VERIFICATION.md.

Build `rojo build studio-test.project.json -o /tmp/toads-studio-tests.rbxlx`. Open the resulting place in Roblox Studio, start a local server, then run in the **server** command bar:

```lua
require(game.ServerStorage.PlayabilityHarness).run()
```

The harness is excluded from the production project. It checks actual generated support and negative mutations, property behavior, ordered checkpoint traversal and dedupe, saved recovery target, personal claim isolation with at least two clients, and connected-player rebuild. It moves test characters directly to checkpoints: it does not substitute for walking/jumping or prove two-second human control recovery. Use a disposable Studio mock session. The harness intentionally fails outside Studio.

| Test | Setup / action | Required observation | Evidence |
| --- | --- | --- | --- |
| Clean boot | New test place, run 1 client | 18 stages, no error or warning; validator passes | Pending |
| Connected route | Walk spawn through 18, every connector | No gap outside budget; no unsupported checkpoint; visible +X arrows | Pending |
| Early lessons | Novice walks 1–3; misses each jump | Catch/ramp obvious; gentle optional bounce; independent solo completion | Pending |
| Conveyor | Jump and steer on Caravan | Y unaffected; forward influence; lateral control remains | Pending |
| Platforms/train | Ride overlapping edges with 1/2/8 clients | No repeated carry, fling, jitter or across-course motion | Pending |
| Timed bars/laser | Remain inside over a complete cycle | O CROSS, ! WARNING, X WAIT agree with damage; never collision wall | Pending |
| Falling root | Stand after warning; wait for reset | >=1.25s warning; permanent catch; no trapping on return | Pending |
| Wind/cart | Enter wind; leave/reset cart | Bounded drift, visible direction; walking lane intact | Pending |
| Recovery | HUD Try again, built-in Reset, fall, active laser | Return to current checkpoint; record control latency distribution, target <=2s | Pending |
| Assistance | Trigger 2, 3, 5 failures and wait 90s | Hint, personal grace, opt-in Help; other player's hazard unchanged | Pending |
| Checkpoints | Repeat and revisit earlier pads | No regression, repeat sound/completion/save spam | Pending |
| Late join | Join after another player reaches chapter 9 | Snapshot has correct totals, settings, progress, key claims | Pending |
| Join/leave | Repeat joins during loads/rebuild | No stale callbacks/profile writes or discarded sessions | Pending |
| Rebuild | Run harness then /rebuild with 1/2/8 clients | Connected players retain progress/keys and future CharacterAdded hooks | Pending |
| Keys/medals | Two players collect same token | Both earn personal Explorer; token never gates story | Pending |
| Personal finale | Only player A finishes while B remains in chapter 8 | A sees celebration/results; B sees no finale screen effects | Pending |
| Replay/select | Finish once; replay/time trial/chapter select | Correct spawn bridge/start gate, selected chapter entry, valid best splits | Pending |
| Portrait phone | Device emulator 360x800 and physical phone | Safe insets, reachable Jump/Move, readable HUD, 48px primary controls | Pending |
| Landscape phone | 800x360 and physical phone | No overlap, clipped settings or obscured route; rotate live | Pending |
| Tablet | Touch and emulator | Same controls, readable warning signs, no fixed-width overflow | Pending |
| Desktop | Keyboard/mouse, resize window | Obvious hints and help; panels scroll; no caret ambiguity | Pending |
| Console/gamepad | Controller only | Every action reachable with selection/activation and panel focus | Pending |
| Pseudolocalization | Client command: Players.LocalPlayer:SetAttribute("PseudoLocalization", true) | Expanded dynamic text wraps; actions remain readable | Pending |
| Accessibility | Toggle large text, motion, flashes, contrast, volumes | Changes persist; semantics preserved; no required audio/color-only cue | Pending |
| Low effects | Toggle before and during finale; stream new objects | No continuous fireworks; ambient particles suppressed; geometry unchanged | Pending |
| Network | Repeat at 150/300ms delay, jitter and 1/5% simulated loss | No progress duplication; acceptable recovery and rider behavior | Pending |
| Persistence | Staging only: save/leave/rejoin, concurrent older write, denied read, shutdown | Monotonic profile; failed read never authorizes destructive save; play continues | Pending |
| Performance | Eight clients, low-end physical mobile, all effects modes | Capture profiler, frame time, memory, server cost; no invented FPS | Pending |
| Human playtest | Consented novice children plus supervising adult | Measure clarity, delight, duration and recovery; no leading prompts | Pending |

Record tester, date, commit, client count, device, settings, network conditions, observed/expected result and evidence link per row. Initial hypotheses: 8–12 minutes, >=90% first-three completion, 80–90% normal completion after assistance. A row is not passed by source inspection.
