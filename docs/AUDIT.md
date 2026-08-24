# Factual audit

Audit baseline: 2026-08-24, branch `codex/toads-great-escape-next-level`.
Latest local implementation evidence includes asset-registry and run-rule
tests in addition to the original progression/profile suites.

## Repository and source of truth

This is a Rojo project. `src/shared` maps to `ReplicatedStorage`, `src/server`
to `ServerScriptService`, `src/client` to `StarterPlayerScripts`, and
`src/workspace` to `Workspace`. The two `.rbxlx` files are binary XML exports;
they are snapshots, not editable source. Their provenance and timestamps need
manual Studio comparison before either is treated as authoritative.

## What exists

- 3 configured zones and 18 named stage templates; generator provenance is
  currently version `3`.
- Deterministic seeded generation, CollectionService obstacle tags, a central
  `ObbyService`, checkpoint service, DataStore wrapper, HUD, and effects.
- Development chat commands for rebuild, reseed, and stage teleport.
- CI installs pinned Stylua/Selene/Rojo tools and runs the full contract gate
  before building a place artifact.

## Baseline findings and current status

- Stage spacing is now owned by the higher-level builder; templates return an
  explicit build result with entrance, exit, bounds, safe spawn, and mechanic
  metadata.
- Workspace cleanup is now restricted to an owned `GeneratedObby` root; an
  unknown root causes rebuild to fail closed.
- Checkpoint progress is now monotonic and state synchronization has an
  explicit initialization request; Studio respawn feel remains unverified.
- Keys are now authored deterministically with stable IDs and per-player credit;
  duplicate-ID validation is active.
- Persistence now has an explicit environment gate, versioned profile schema,
  bounded retry wrapper, autosave, concurrent bounded shutdown saves, and
  executable pure-Luau migration/bounds tests. Live DataStore behavior still
  requires Studio validation.
- `ObbyService` uses a server Heartbeat for critical motion and bounded 10 Hz
  queries for wind and pressure pads; moving-platform rider correction remains
  a Studio physics validation item.
- Lighting presentation now transitions locally by zone and decoration is
  anchored from zone bounds; Studio visual verification remains pending.
- Asset references are inventoried and unverified IDs are gated from release
  music and finale effects; asset permissions and playback remain pending
  Creator Hub/Studio.
- UI now has an initial state handshake, settings, mode, responsive touch
  targets, and accessibility controls; device and gamepad behavior remain
  unverified.
- Original local vector branding and Golden Key source art are present under
  `art/`; Roblox upload and in-game rendering remain unverified.
- Server capacity configuration is now intentionally left to Creator Hub;
  unused Lua capacity knobs are not treated as effective settings.
- Automated confidence includes configuration, storyboard, production, Stylua,
  Selene, pure-Luau progression/profile/run-rule/asset tests, and CI Rojo-build
  gates; runtime traversal still requires Studio.

## Not claimed as tested

No Roblox Studio integration is available in this environment. Playability,
mobile/gamepad behavior, multiplayer physics, asset permissions, DataStore
behavior, frame rate, and Studio Output are therefore pending Studio execution.

## First implementation priorities

1. Stable stage/progression/ownership contracts and validation.
2. Server-authoritative profile and per-player collectible state.
3. Remote/state synchronization and safe development commands.
4. Performance and presentation improvements that can be verified locally.
