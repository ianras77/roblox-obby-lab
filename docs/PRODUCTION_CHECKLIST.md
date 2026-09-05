# Production checklist

Release decision: **NOT READY for release**. Source and non-Studio checks are implemented; Studio integration, physical playability, device usability, performance, analytics delivery and human fun are unverified. The generated artifacts are candidates for private Studio testing, not a certified production experience.

- [x] Reconcile current checkout with main; preserve newer feature work and incoming conveyor intent.
- [x] Connected authored route, catch floors, real stage/zone/spawn/finale connectors.
- [x] Canonical 18 definitions, numeric route tests, runtime support/footprint/hazard/controller validator.
- [x] Explicit build property application and executable property tests.
- [x] Single startup, deduplicated movement, noncolliding phased lasers, local recovery/help.
- [x] Personal keys, sequential checkpoints, initial snapshot, profile/session retention on rebuild.
- [x] Schema v2, monotonic UpdateAsync merge, isolated environment namespaces, default Studio mock, bounded loading, autosave/milestone/leave/close paths.
- [x] Safe-inset HUD, input hints, gamepad-selectable controls, reduced effects, Studio pseudolocalization mode.
- [x] Story/Explorer/Toad medals, completion unlock for timed mode and chapter select.
- [x] Server analytics wrapper and explicit measurement plan.
- [x] Local automated checks and production/test Rojo builds; no graphical Studio required in CI.
- [ ] Run Studio harness on 1, 2 and 8 clients with no errors/warnings.
- [ ] Walk/jump every required chapter and rescue route on touch and gamepad.
- [ ] Validate personal finale/key visibility and real connected-player rebuild under replication.
- [ ] Exercise staging persistence failures, concurrent sessions and shutdown in real Roblox services.
- [ ] Complete every manual/device/network/accessibility row in PLAYTEST_MATRIX.
- [ ] Measure frame time, memory, server update cost and recovery latency.
- [ ] Verify analytics in staging, approved assets and user testing before limited release.

Persistence defaults to `StudioDevelopment`: Studio uses an in-memory mock; a non-Studio server with this environment writes nothing. `StudioSandbox` uses a separate namespace for opt-in Studio datastore work. Staging and Production each append their environment to the store name. Production requires an explicit reviewed GameConfig environment change, UseDataStore and SaveCheckpoints. No Creator Dashboard setting was changed. Max-merge completion counts prevent regression but are not an additive multi-session counter; simultaneous completions can undercount. Settings use the sanitized session preference values.

Do not publish from this change. Do not infer success from an artifact build. No Robux, purchases, lives, required collectible, pay-to-skip or co-op requirement is introduced. Infinite retry and assistance are the player promise; actual recovery speed remains a measurement gate.
