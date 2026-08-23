# Implementation log

## 2026-08-23 — Route results Practice through chapter selection

- Completed: the completion-card Practice action now opens the existing
  server-validated chapter selector instead of switching to Practice without a
  target stage.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: results-to-practice interaction and device layout require Studio.

## 2026-08-23 — Remove misleading placeholder test

- Completed: removed the unused always-pass `tests/placeholder.lua`; executable
  confidence gates remain explicitly maintained under `scripts/` and CI.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: dynamic Luau runtime tests still require a Roblox/Luau runner.

## 2026-08-23 — Scope collectible validation to generated stages

- Completed: validator duplicate/missing-key checks now inspect only
  `KeyCollectible` instances inside generated stage models, matching the
  ownership scope used by runtime registration.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: coexistence with tagged user content requires Studio testing.

## 2026-08-23 — Scope obstacle discovery to owned world

- Completed: CollectionService-tagged obstacle, cart, and collectible scans
  now register only instances beneath the current generated world, preventing
  unrelated Workspace content from entering runtime behavior or key totals.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live tagged user-content coexistence requires Studio testing.

## 2026-08-23 — Add original art source briefs

- Completed: added organized source-art prompt briefs for the logo, icon, and
  eighteen-card chapter package without claiming generated files or uploaded
  Roblox assets.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: raster generation, originality review, and Creator Hub uploads
  require the unavailable art workflow and manual review.

## 2026-08-23 — Make validator instance guards type-safe

- Completed: model and checkpoint validation now checks Luau instance type
  before calling Roblox `IsA`/descendant APIs, preventing malformed scalar
  fields from crashing world validation.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: malformed live template output remains a Studio-only check.

## 2026-08-23 — Gate cart motion on riders

- Completed: generated carts now remain stationary until their server-owned
  seat has an occupant, stop while empty, and reset after five seconds of
  abandonment or after the existing route timeout/fall recovery.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: seat boarding, dismount, and multiplayer cart behavior require
  Studio playtesting.

## 2026-08-23 — Reject non-finite stage geometry

- Completed: world validation now rejects NaN/infinite bounds and stage
  entrance, exit, or safe-spawn positions before geometry arithmetic.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: malformed numeric values in live Studio remain unverified.

## 2026-08-23 — Validate structured stage result types

- Completed: world validation now checks CFrame, Vector3, and mechanics-table
  types before using stage result fields in geometry checks, making malformed
  template returns fail with diagnostics instead of runtime errors.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: malformed-template behavior in live Studio remains unverified.

## 2026-08-23 — Bound checkpoint root readiness

- Completed: safe checkpoint teleports now wait up to five seconds for a
  character `HumanoidRootPart` and verify its type, preventing slow character
  assembly from silently skipping restored placement.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: real device spawn timing requires Studio testing.

## 2026-08-23 — Guard checkpoint binding at runtime

- Completed: checkpoint event binding now requires a `BasePart` and warns on
  invalid manifest entries, adding runtime defense beyond world-build
  validation.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: malformed live rebuild behavior requires Studio testing.

## 2026-08-23 — Restrict physics touches to live players

- Completed: conveyor and bounce-pad forces now require a live player
  character, preventing arbitrary HumanoidRootPart-bearing objects from
  activating gameplay physics.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live NPC/multiplayer physics behavior requires Studio testing.

## 2026-08-23 — Guard profile loads after player departure

- Completed: profile-load coroutines now stop and clear session tables when a
  player leaves while `GetAsync` is yielding, preventing late event-handler
  installation and stale in-memory profiles.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live leave-during-load behavior requires staging DataStore tests.

## 2026-08-23 — Bind developer commands across service lifecycle

- Completed: allowlisted developer command handlers now bind both existing and
  future players, so service startup and Studio rebuilds do not leave present
  operators without `/rebuild`, `/reseed`, or `/stage` access.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live chat command behavior requires Studio testing.

## 2026-08-23 — Snapshot profiles before datastore writes

- Completed: saves now sanitize a stable profile snapshot before entering the
  yielding `UpdateAsync` path, preventing concurrent touches/settings changes
  from mutating the value mid-save.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live concurrent save behavior requires staging DataStore tests.

## 2026-08-23 — Require a live character at the Time Trial gate

- Completed: Time Trial gate admission now requires a live Humanoid in addition
  to a valid root and distance check, preventing dead characters from arming
  the server clock.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live gate touch timing requires Studio playtesting.

## 2026-08-23 — Baseline and correctness foundation

- Completed: repository audit and development branch creation.
- Completed: identified stage spacing, ownership, checkpoint, collectible,
  persistence, and state-sync risks.
- Tests: storyboard contract passed; `git diff --check` passed; full local check
  is blocked by missing `selene` in the environment.
- Observed: Studio-only gameplay and performance verification remains pending.
- Next executable step: wire stable stage metadata and world validation, then
  migrate progression and keys to server-owned state.

## 2026-08-23 — Ownership and progression contracts

- Completed: generated-world ownership markers and versioned seed metadata.
- Completed: stable stage IDs, validator wiring, monotonic checkpoints, and
  per-player key credit without global key destruction.
- Tests: storyboard and production contracts pass; Stylua check passes;
  Selene is unavailable in this environment.
- Next executable step: replace the checkpoint-only wrapper with a versioned
  profile service and explicit client state synchronization.

## 2026-08-23 — Replay-safe run state

- Completed: server-owned Adventure, TimeTrial, and Practice run state, chapter
  timing, and split storage; Practice completion cannot qualify.
- Completed: initialization synchronization includes run mode and timing data.
- Tests: storyboard, production contracts, Stylua, and whitespace checks pass.

## 2026-08-23 — DataStore key correctness

- Completed: profile reads/writes now use stable string keys prefixed with
  `player:` as required by the Roblox DataStore API.
- Tests: local contracts and formatting remain the baseline; live DataStore
  availability and migration behavior remain unverified.
- Unverified: time-trial UX, leaderboard policy, and Studio gameplay.

## 2026-08-23 — Persisted accessibility settings

- Completed: allowlisted, rate-limited settings remote and profile-backed
  accessibility settings restoration through `GetObbyState`.
- Tests: storyboard, production contracts, Stylua, and whitespace checks
  remain the local validation baseline.
- Unverified: settings behavior across real device respawn and Studio clients.

## 2026-08-23 — Replay controls and results presentation

- Completed: server-validated mode selection and a completion results panel for
  Adventure, Time Trial, and Practice.
- Completed: Practice remains explicitly ineligible in server run state.
- Tests: storyboard, production contracts, Stylua, and whitespace checks pass.
- Unverified: device layout, actual timing flow, and Studio multiplayer behavior.

## 2026-08-23 — Server-owned run results

- Completed: qualifying completions update personal best and completion count;
  deaths update profile totals; results show the personal best.
- Completed: Practice completions remain excluded from personal-best updates.
- Tests: storyboard, production contracts, Stylua, and whitespace checks pass.
- Unverified: real Studio timing, reset semantics, and leaderboard publication.

## 2026-08-23 — Removed startup state race

- Completed: removed the synthetic global Stage 0 broadcast; restored client
  state now comes only from `GetObbyState` and per-player events.
- Tests: storyboard, production contracts, Stylua, and whitespace checks pass.

## 2026-08-23 — CI build confidence

- Completed: CI now installs pinned Rojo and builds a place artifact after
  source checks, so project-tree/mapping failures fail the pipeline.
- Tests: local storyboard, production contracts, Stylua, and whitespace checks
  remain passing; CI execution and Rojo installation are not available locally.

## 2026-08-23 — Legacy profile migration

- Completed: sanitizer migrates legacy checkpoint records and bounds run/chapter
  timing fields before storing them.
- Tests: storyboard, production contracts, Stylua, and whitespace checks pass.
- Unverified: live migration against Roblox DataStore records.

## 2026-08-23 — No-op-safe analytics boundary

- Completed: allowlisted server analytics wrapper wired to joins, chapter
  checkpoints, key discovery, and qualifying run completion.
- Completed: analytics is disabled in Studio and by default; no raw chat or
  arbitrary client event payloads are accepted.
- Tests: storyboard, production contracts, Stylua, Selene, and Rojo CI passed
  on the prior validated branch state; this update needs a fresh CI run.

## 2026-08-23 — Vision and art-direction artifacts

- Completed: added the required game-vision and art-direction source documents.
- Scope: documents preserve the literary/public-domain identity and define the
  implemented readability/accessibility direction without claiming uploaded
  assets or Studio visual validation.

## 2026-08-23 — GitHub CI green

- Completed: draft PR CI run `32657495468` passed Stylua, Selene, contract
  checks, and the pinned Rojo place build.
- Evidence: GitHub Actions job completed successfully; this does not replace
  Roblox Studio playtesting or device/multiplayer validation.

## 2026-08-23 — Operator documentation alignment

- Completed: README and test documentation now describe the production contract
  gate and Rojo artifact build rather than the original prototype-only checks.
- Tests: no runtime code changed; prior local and GitHub validation remains the
  evidence baseline.

## 2026-08-23 — Canonical route contract

- Completed: added a deterministic configuration contract for the ordered 18-
  chapter route, unique stage types, matching display names, matching chapter
  presentation metadata, and stable ID derivation.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: actual Roblox Studio traversal, physics, device layout, and
  multiplayer behavior.

## 2026-08-23 — Checkpoint geometry validation

- Completed: WorldValidator now rejects non-positive stage bounds, undersized
  checkpoint standing areas, safe spawns that are not above their checkpoint,
  and checkpoint/hazard overlap.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: physical jump feasibility and respawn feel still require Studio.

## 2026-08-23 — Obstacle lifecycle hardening

- Completed: conveyor motion now preserves the player's vertical velocity
  instead of multiplying it by conveyor speed; centralized animation/query
  loops skip destroyed or detached obstacle instances safely.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: moving-platform rider feel and networked physics still require
  multi-client Studio playtesting.

## 2026-08-23 — Generator fail-closed behavior

- Completed: StageBuilder no longer substitutes the warm-up chapter when a
  template is missing, and now rejects invalid template models, exits, and
  presentation metadata before creating progression objects.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: Studio-only geometry traversal remains pending.

## 2026-08-23 — Contextual hazard authority

- Completed: kill hazards now require a live player character with a root part
  and use a short server-side humanoid debounce before applying death.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: latency behavior and full failure/respawn feel still require
  Studio playtesting.

## 2026-08-23 — Profile-safe collectible handoff

- Completed: key touches now wait for the player's profile load, validate the
  stable key identity type and length, and ignore detached collectible parts.
  This prevents an early touch from being overwritten by asynchronous profile
  loading.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: live DataStore latency and Studio multi-client collection remain
  pending.

## 2026-08-23 — Explicit Time Trial start gate

- Completed: Time Trial runs now arm on mode selection and start only when the
  player crosses a server-owned start gate within a validated distance. The
  Adventure and Practice clocks retain their immediate-start behavior.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: timing feel, reset behavior, and multiplayer gate crossings still
  require Studio playtesting.

## 2026-08-23 — Fail-closed world acceptance

- Completed: WorldBuilder now destroys and rejects generated content when
  WorldValidator reports any error, instead of warning and serving an invalid
  layout.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: validator behavior against live Studio physics remains pending.

## 2026-08-23 — Safe DataStore read failure

- Completed: DataStore reads now return an explicit success flag. A failed
  profile load supplies temporary defaults for gameplay but marks the player
  unavailable for persistence, preventing shutdown/autosave from overwriting
  existing data with defaults.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: live request-budget behavior and recovery after transient Roblox
  DataStore outages require Studio/production-like testing.

## 2026-08-23 — Structured completion results

- Completed: completion now presents a structured player-local results card
  with time, personal best, deaths, Golden Keys, completion percentage, and
  Replay/Time Trial/Practice actions using the existing server-validated mode
  contract.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: responsive layout and gamepad focus still require Studio device
  testing.

## 2026-08-23 — Authorized practice-stage selection

- Completed: Practice now has a server-validated stage-selection contract that
  accepts only integer chapters already reached by the player's loaded profile,
  resets the run state to Practice, and teleports through the existing safe
  checkpoint path.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: selector presentation and multiplayer practice transitions still
  require Studio testing.

## 2026-08-23 — Live Practice unlock synchronization

- Completed: the client now advances its unlocked Practice chapter state from
  monotonic progress events, so a newly reached chapter becomes selectable in
  the current session.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: device layout and multiplayer UI behavior remain pending Studio.

## 2026-08-23 — Explicit stage manifest cardinality

- Completed: WorldValidator now checks stage order and index uniqueness
  independently of sparse checkpoint arrays, verifies the configured total
  stage count, and reports missing stage indices separately from missing
  checkpoints.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: live generated geometry traversal remains pending Studio.

## 2026-08-23 — DataStore budget gates

- Completed: profile reads and writes now check Roblox request budget before
  each attempt. Exhausted budgets fail safely, retaining session defaults or
  unsaved in-memory progress rather than adding more pressure to the service.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: live budget values and outage recovery require production-like
  Roblox testing.

## 2026-08-23 — Owned rebuild deletion guard

- Completed: rebuild cleanup now verifies the generated root's
  `GeneratorOwner` attribute before deleting it and fails closed for an
  unknown or user-created `GeneratedObby` model.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: Studio rebuild behavior with user-authored Workspace content
  remains pending.

## 2026-08-23 — World seed boundary validation

- Completed: the world-generation entry point now accepts only finite,
  non-negative integer seeds within the configured developer range, preventing
  direct callers from bypassing reseed input limits.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: Studio rebuild behavior with extreme but valid seeds remains
  pending.

## 2026-08-23 — Immediate checkpoint profile consistency

- Completed: checkpoint advancement now updates the loaded in-memory profile as
  well as player attributes, keeping server Practice authorization consistent
  with the chapter just reached before autosave runs.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: Studio persistence timing and reconnect behavior remain pending.

## 2026-08-23 — Moving-platform rider deduplication

- Completed: platform carrying now updates each character at most once per
  frame, applies platform horizontal velocity without accumulating it, and
  preserves the rider's vertical velocity.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: actual rider comfort, edge standing, latency, and multi-client
  physics require Studio testing.

## 2026-08-23 — Feedback asset approval boundary

- Completed: checkpoint and Golden Key feedback sounds now resolve through
  AssetRegistry and remain silent until an asset is both verified and approved
  for release.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: Roblox asset ownership, moderation, and playback require Creator
  Hub/Studio verification.

## 2026-08-23 — Client finale asset gate

- Completed: client fireworks texture and finale chime now use AssetRegistry;
  unapproved assets produce safe empty fallbacks, and reduced-particle mode
  also lowers the emitted burst count.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: asset playback and finale presentation remain Studio-dependent.

## 2026-08-23 — Reversible high-contrast hazards

- Completed: high-contrast mode now snapshots and restores hazard materials as
  well as colors, so toggling the accessibility setting does not leave a
  permanent client-side visual mutation.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: visual readability on real devices remains pending Studio.

## 2026-08-23 — Subtle checkpoint feedback

- Completed: ordinary checkpoint progress now uses a small HUD pulse rather
  than a full-screen white flash; the pulse respects reduced-motion and
  reduced-flash settings while finale presentation remains separate.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: visual timing and accessibility perception require Studio device
  testing.

## 2026-08-23 — Generated visual asset gate

- Completed: generated particle textures and the legacy chapter decal now
  resolve through AssetRegistry; direct Roblox asset literals were removed
  from builders and shared build utilities.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: ownership, moderation, and visual playback require Creator
  Hub/Studio verification.

## 2026-08-23 — Zone ambience asset gate

- Completed: all three zone ambience references now use logical registry keys
  and resolve through AssetRegistry approval instead of assigning raw IDs from
  zone configuration.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally; GitHub CI was green before this change.
- Unverified: ambience ownership, moderation, and playback remain Creator
  Hub/Studio checks.

## 2026-08-23 — Bounded collectible profile input

- Completed: profile sanitization and runtime key credit now cap stored
  collectible identities at 100, bounding malformed persistence payloads while
  leaving the authored 18-key route unaffected.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: live migration of oversized legacy records remains pending.

## 2026-08-23 — Live Time Trial HUD timer

- Completed: added a client-rendered Time Trial timer synchronized from server
  mode/start events; it displays elapsed time only and does not participate in
  eligibility, completion, or record decisions.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: clock presentation, drift, and device layout require Studio.

## 2026-08-23 — Merge chapter splits and settings safely

- Completed: concurrent profile updates now preserve the best chapter split and
  boolean settings from the existing record, while retaining bounded key-state
  merging.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: concurrent live DataStore conflict behavior requires a staging
  Roblox environment.

## 2026-08-23 — Bound merged collectible records

- Completed: concurrent profile merging now rebuilds the key set from both
  records with type, length, and 100-key bounds, instead of copying an
  unbounded table and only limiting one side.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live DataStore conflict and migration behavior still require
  staging Roblox validation.

## 2026-08-23 — Make world validation fail closed

- Completed: malformed stage manifests with missing or non-Model instances now
  produce validation errors instead of crashing during attribute, hazard, or
  descendant inspection.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: validator execution against live generated instances remains a
  Studio-only check.

## 2026-08-23 — Bound persisted chapter progress

- Completed: profile sanitization now clamps legacy and current
  `highestChapter` values to the canonical 18-chapter route, preventing
  malformed records from advertising impossible progression.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live migration of malicious or corrupt records requires staging
  DataStore validation.

## 2026-08-23 — Bound persisted profile counters

- Completed: death and completion counters are now clamped to a sane upper
  bound during profile sanitization, preventing corrupt records from inflating
  HUD values or concurrent-save merges.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live migration of extreme counter values requires staging
  DataStore validation.

## 2026-08-23 — Gate progression on profile readiness

- Completed: checkpoint advancement now requires a successfully loaded player
  profile before accepting touches, preventing early-join progression from
  mutating session defaults during a DataStore load race.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: join/load timing under live DataStore latency requires Studio or
  staging validation.

## 2026-08-23 — Establish checkpoint state on profile load

- Completed: profile loading now clears stale checkpoint attributes before
  applying sanitized saved progress, including explicit zero-progress state;
  this prevents old-world state from surviving a rebuild or new load.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live reconnect and rebuild timing require Studio/staging tests.

## 2026-08-23 — Repair character position after profile load

- Completed: when a profile load finishes after character spawn, the service
  now teleports the existing character to the sanitized saved checkpoint;
  future `CharacterAdded` events retain the same safe-spawn path.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live join latency and spawn ordering require Studio/staging.

## 2026-08-23 — Reset run completion state

- Completed: server run initialization and mode changes now clear the previous
  `RunCompleted` attribute before a new run begins, preventing stale completion
  state from leaking into replay or future reward logic.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: full replay attribute behavior requires Studio playtesting.

## 2026-08-23 — Tear down services before rebuild

- Completed: developer rebuilds now destroy the old checkpoint/run services and
  reset runtime clocks before constructing the replacement world, preventing
  stale touch handlers and timing state from overlapping a rebuild.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: repeated Studio rebuilds and active-player behavior require
  Studio testing.

## 2026-08-23 — Gate settings and modes on profile readiness

- Completed: accessibility-settings and run-mode remotes now reject requests
  until the server has loaded the player's profile, preventing initialization
  races from mutating or replacing session defaults.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: remote timing under live DataStore latency requires Studio or
  staging validation.

## 2026-08-23 — Align live network payload contracts

- Completed: progress contracts now document server-synchronized timer fields,
  and Golden Key pickup feedback includes the stable server-assigned key ID.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live client compatibility and multiplayer pickup presentation
  require Studio testing.

## 2026-08-23 — Bound concurrent chapter split merges

- Completed: `UpdateAsync` now accepts existing chapter splits only for integer
  chapters 1–18 and finite positive times below the profile timing ceiling,
  preventing malformed legacy fields from being reintroduced during saves.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live malformed-record migration requires staging DataStore
  testing.

## 2026-08-23 — Guard invalid checkpoint instances

- Completed: the world validator now inspects checkpoint geometry only after
  confirming the checkpoint is a `BasePart`, so malformed checkpoint instances
  return validation errors without crashing the build.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live malformed-instance coverage still requires Studio.

## 2026-08-23 — Restart Time Trials from a clean start

- Completed: selecting Time Trial, including using Reset while already in a
  trial, now clears the server-owned checkpoint before the character respawns.
  Adventure resets retain ordinary checkpoint behavior.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: respawn placement and gate re-entry timing require Studio.

## 2026-08-23 — Bounded rider contact queries

- Completed: moving-platform contact detection now samples `GetTouchingParts()`
  at 20 Hz and reuses the contact list for per-frame translation, while still
  deduplicating characters and preserving vertical velocity.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: contact freshness and ride feel under latency require Studio
  multiplayer testing.

## 2026-08-23 — Isolated Studio sandbox store

- Completed: `StudioSandbox` now appends `_StudioSandbox` to the configured
  DataStore name, preventing test profiles from sharing production records;
  `Production` remains blocked while running in Studio.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: Roblox API access and sandbox request budgets require Studio
  verification.

## 2026-08-23 — Explicit completion payload contract

- Completed: RemoteContracts now documents the chapter metadata and completion
  metrics actually sent by the server, including timing, deaths, keys, and
  chapter splits.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: runtime payload observation requires Studio client testing.

## 2026-08-23 — Scrollable settings panel

- Completed: the settings/mode panel now uses automatic vertical canvas sizing
  and scrolling so all accessibility, replay, and mode controls remain
  reachable when the panel exceeds the viewport height.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: touch scrolling and gamepad focus order require Studio device
  testing.

## 2026-08-23 — Time Trial plausibility guard

- Completed: server-owned Time Trial completion now requires a conservative
  minimum elapsed duration before updating personal-best data; implausibly fast
  runs still complete for the player but are ineligible for record updates.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: threshold tuning against real movement and latency requires
  Studio playtesting.

## 2026-08-23 — Cross-input HUD activation

- Completed: reset, settings, mode, and accessibility controls now use the
  cross-input `Activated` event, matching the intended touch/gamepad/desktop
  surface.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: actual gamepad focus order and device ergonomics require Studio.

## 2026-08-23 — Explicit selectable HUD controls

- Completed: reset, settings, mode, Practice chapter, accessibility, and
  results actions are explicitly marked selectable for gamepad navigation.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: actual selection order and console safe-area behavior require
  Studio testing.

## 2026-08-23 — Canonical Time Trial start

- Completed: crossing the validated Time Trial gate now clears the player's
  saved checkpoint attributes before starting the clock, preventing late-game
  checkpoint progress from producing an invalid shortened run.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: reset/spawn timing and full-run plausibility require Studio.

## 2026-08-23 — Rate-limit lifecycle cleanup

- Completed: settings, run-mode, and Practice remote rate-limit maps now remove
  disconnected players, preventing stale player-keyed state from accumulating
  across repeated joins.
- Tests: configuration, storyboard, production, Stylua, and whitespace checks
  pass locally.
- Unverified: long-lived server memory behavior requires live server soak tests.

## 2026-08-23 — Profile contract gate

- Completed: added an executable profile contract covering required defaults,
  legacy checkpoint migration, timing bounds, boolean settings validation, and
  the bounded collectible-key set; integrated it into `scripts/check.sh` and CI.
- Tests: configuration, profile, storyboard, production, Stylua, and whitespace
  checks pass locally.
- Unverified: dynamic Luau execution and live DataStore migration still require
  Studio/production-like testing.

## 2026-08-23 — Bound stored values during concurrent saves

- Completed: `UpdateAsync` now applies the profile chapter and counter ceilings
  to existing stored records as well as the current session value.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: live malformed-record migration requires staging DataStore tests.

## 2026-08-23 — Preserve monotonic progress on save

- Completed: profile saves now retain the greater of stored session progress and
  the current checkpoint attribute, so Time Trial resets cannot lower a
  player's saved Adventure progression before `UpdateAsync` runs.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: leave-during-trial and live save ordering require Studio/staging.

## 2026-08-23 — Submit allowlisted analytics events

- Completed: the server analytics wrapper now submits allowlisted events to
  Roblox AnalyticsService when explicitly enabled outside Studio, using a
  protected call and fixed low-cardinality value.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: Creator Hub analytics availability and delivery require staging.

## 2026-08-23 — Reconcile persistence and performance documentation

- Completed: corrected release documentation to describe the implemented
  versioned profile/persistence path and the actual 10 Hz wind/pad and 20 Hz
  moving-platform query cadence.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: Roblox DataStore behavior and runtime performance still require
  staging/Studio measurement.

## 2026-08-23 — Bound non-critical obstacle updates

- Completed: rotators, gavel animation, and timed-tile state updates now run at
  a bounded 30 Hz server tick, while moving-platform and critical hazard paths
  retain their existing authority cadence.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: server cost and perceived motion quality require Studio
  profiling and playtesting.

## 2026-08-23 — Synchronize initial environment presentation

- Completed: the local environment controller now requests `GetObbyState` on
  startup and applies the restored chapter's zone presentation before later
  progress events arrive.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: visual transition quality and lighting replication require
  Studio/device testing.

## 2026-08-23 — Bound environment transition lifecycle

- Completed: zone presentation now cancels prior Lighting, Atmosphere, and
  ColorCorrection tweens before starting a new transition, preventing stacked
  animations during rapid progression.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally.
- Unverified: visual smoothness and device performance require Studio testing.

## 2026-08-23 — Return Time Trial players to the start gate

- Completed: the generated start gate is exposed in the world result, and
  selecting Time Trial clears progression and returns the live character to a
  safe position behind the gate.
- Tests: configuration, profile, storyboard, production, and Stylua checks
  pass locally; the aggregate check is blocked here because `selene` is not
  installed.
- Unverified: the respawn/teleport presentation and gate crossing still
  require Roblox Studio playtesting.

## 2026-08-23 — Make Practice chapter respawns coherent

- Completed: selecting an unlocked Practice chapter now assigns a temporary
  server-owned checkpoint before teleporting, so death respawns within the
  selected chapter without changing persisted highest progress.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: multi-client Practice/reset behavior requires Studio testing.

## 2026-08-23 — Persist Time Trial timer visibility

- Completed: `showTimer` is now part of the validated profile defaults and
  settings UI; hiding it affects presentation only, while server timing and
  eligibility remain unchanged.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: settings persistence and device-specific HUD placement require
  Studio testing.

## 2026-08-23 — Align chapter split bounds with the canonical route

- Completed: profile sanitization now rejects chapter split records beyond
  `ProfileSchema.MaxChapter`, preventing stale or malformed records from
  creating split entries outside the 18-chapter route.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: migration behavior against live legacy records requires a
  Studio sandbox DataStore run.

## 2026-08-23 — Route audio through production SoundGroups

- Completed: server startup now creates shared Music, Ambience, SFX, and UI
  buses; approved music, zone ambience, and finale feedback are assigned to
  the appropriate groups while unapproved assets still resolve to silence.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: actual audio playback, permissions, and device mixing require
  Creator Hub and Studio verification.

## 2026-08-23 — Move developer commands to TextChatService

- Completed: `/rebuild`, `/reseed`, and `/stage` now use explicit server-side
  `TextChatCommand` aliases with the existing allowlist, bounds, and cooldown;
  legacy `Player.Chatted` is retained only as a compatibility fallback.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: command behavior in current Roblox Studio chat channels requires
  Studio testing.

## 2026-08-23 — Add zone-relative story landmarks

- Completed: `DecorBuilder` now places anchored, non-collidable landmark kits
  from measured zone bounds, giving the three zones distinct silhouettes and
  orientation cues without adding gameplay-path geometry.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: landmark composition, occlusion, and mobile render cost require
  Studio/device inspection.

## 2026-08-23 — Sleep distant cosmetic mechanics

- Completed: non-critical rotators, gavel presentation, timed-tile visuals, and
  beacons now use a bounded 180-stud proximity check; critical hazards,
  moving-platform transforms, and transport authority remain active.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: actual server frame-time savings and wake-up presentation require
  Roblox MicroProfiler and multi-player Studio testing.

## 2026-08-23 — Emit the documented chapter-start event

- Completed: the server now emits the allowlisted `chapter_started` event at
  the first monotonic checkpoint transition for a chapter, alongside the
  existing completion event; client payloads cannot create analytics events.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: production telemetry delivery remains disabled until analytics
  policy and destination approval.

## 2026-08-23 — Hide collected keys per player

- Completed: initial state synchronization and key pickup feedback now apply
  local visibility for collected stable key IDs; the shared physical key is
  never destroyed, preserving independent multiplayer collection.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: late streaming of key instances and two-client visual isolation
  require Studio multiplayer testing.

## 2026-08-23 — Make finale reduced-motion safe

- Completed: Reduced Motion now suppresses finale fireworks and spotlight
  animation while retaining the completion transition and results presentation.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: nausea/accessibility review and device behavior require Studio
  testing with the setting enabled.

## 2026-08-23 — Keep Adventure runs out of Time Trial bests

- Completed: final completion still increments the unlock counter in Adventure,
  but `bestRunMs` is now updated only for eligible Time Trial runs; Practice
  remains ineligible.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: end-to-end PB preservation across real profile saves requires
  Studio sandbox DataStore testing.

## 2026-08-23 — Correct settings and test-status documentation

- Completed: documentation now reflects six supported boolean accessibility
  settings, including `showTimer`, and no longer implies that a missing Luau
  test runner exists locally.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: runtime test execution still requires Roblox Studio or a chosen
  Luau runner.

## 2026-08-23 — Make Adventure Replay restart from the start

- Completed: selecting Adventure now clears the live checkpoint and returns
  the character to the start gate, while preserving persisted unlock progress,
  keys, and Time Trial personal bests.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: Results Replay positioning and persistence preservation require
  Studio playtesting.

## 2026-08-23 — Route checkpoint and key sounds through SFX

- Completed: generated checkpoint and Golden Key feedback now use the shared
  SFX SoundGroup alongside finale feedback; no sound path bypasses the common
  mix buses.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: approved asset playback and final mix balance require Creator Hub
  and Studio verification.

## 2026-08-23 — Make SoundGroup setup startup-order safe

- Completed: shared `SoundGroups.ensure` now idempotently creates and assigns
  the Music, Ambience, SFX, and UI buses from every sound creation path, even
  if the compatibility bootstrap starts before `ServerMain`.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: Studio script scheduling and final device mix still require
  Roblox testing.

## 2026-08-23 — Add persistent local audio controls

- Completed: players can cycle master, music, and effects volume from the
  responsive settings panel; values are range-validated, persisted in the
  profile, and applied locally to the shared SoundGroup buses.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: actual device mixing, mute ergonomics, and persistence in a live
  profile require Studio testing.

## 2026-08-23 — Preserve numeric settings during concurrent saves

- Completed: `UpdateAsync` now retains bounded numeric volume and UI-scale
  settings from the existing profile record instead of merging booleans only.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: real concurrent-session conflict behavior requires a staging
  DataStore test.

## 2026-08-23 — Apply settings before initial HUD presentation

- Completed: the client now applies persisted accessibility and audio settings
  before rendering the initial timer, progress, key state, and effects, avoiding
  a transient default presentation during join synchronization.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: visible join-time behavior under real network latency requires
  Studio testing.

## 2026-08-23 — Record and validate connector ownership

- Completed: the stage manifest now records each stage's measured connector
  length and expected zone index; `WorldValidator` rejects mismatches, overly
  long links, nonzero first-stage connectors, and incorrect zone ownership.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: generated CFrame spacing and traversal feasibility still require
  Studio inspection.

## 2026-08-23 — Measure cross-zone connectors

- Completed: connector measurement now carries the prior zone exit into the
  next zone, so the first stage of each zone records and validates the actual
  elevation-transition link instead of falsely starting at zero.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: cross-zone traversal remains a Studio geometry/playtest check.

## 2026-08-23 — Bind zone ownership to generated models

- Completed: each generated stage model now carries its `ZoneIndex`, and the
  validator compares that marker with the stage manifest and expected route
  zone before accepting the world.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: live Studio inspection of generated hierarchy remains pending.

## 2026-08-23 — Validate stage zone hierarchy

- Completed: manifests retain each stage's zone container reference, and the
  validator rejects stages whose parent no longer matches that container even
  when their `ZoneIndex` attribute is unchanged.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: live hierarchy mutation behavior remains a Studio-only check.

## 2026-08-23 — Fail closed on missing zone containers

- Completed: `WorldValidator` now requires a typed zone-model reference before
  evaluating parent identity, rejecting manifests that omit the container and
  would otherwise bypass hierarchy validation.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: malformed live instances still require Studio mutation tests.

## 2026-08-23 — Harden malformed stage diagnostics

- Completed: `WorldValidator` now requires bounded string stage IDs and finite
  integer stage indices, and uses safe labels while formatting errors so bad
  manifest values produce validation errors instead of formatter crashes.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: malformed live instance injection remains a Studio-only test.

## 2026-08-23 — Separate route and exploration completion

- Completed: the results screen now reports route completion separately from
  Golden Key exploration percentage, preventing a finished run with missing
  optional keys from appearing fully explored.
- Tests: configuration, profile, storyboard, production, Stylua, and
  whitespace checks pass locally; Selene remains CI-only in this environment.
- Unverified: final-results readability on mobile and large-text settings
  requires Studio device testing.
