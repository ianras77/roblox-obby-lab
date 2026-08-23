# Factual audit

Audit baseline: 2026-08-23, branch `codex/toads-great-escape-next-level`.

## Repository and source of truth

This is a Rojo project. `src/shared` maps to `ReplicatedStorage`, `src/server`
to `ServerScriptService`, `src/client` to `StarterPlayerScripts`, and
`src/workspace` to `Workspace`. The two `.rbxlx` files are binary XML exports;
they are snapshots, not editable source. Their provenance and timestamps need
manual Studio comparison before either is treated as authoritative.

## What exists

- 3 configured zones and 18 named stage templates.
- Deterministic seeded generation, CollectionService obstacle tags, a central
  `ObbyService`, checkpoint service, DataStore wrapper, HUD, and effects.
- Development chat commands for rebuild, reseed, and stage teleport.
- CI installs pinned Stylua/Selene and runs the storyboard contract.

## Verified weaknesses

- `ZoneBuilder` and `WorldBuilder` both add spacing after stage/zone exits.
- Template output is only an end CFrame; no explicit entrance, exit, bounds,
  safe spawn, mechanics, or validator contract exists.
- Workspace cleanup uses broad names (`Obby`, `Weather`).
- A checkpoint touch always overwrites the player's checkpoint, including with
  an earlier stage; progress is broadcast only after a touch.
- Keys are now authored deterministically with stable IDs and per-player credit;
  duplicate-ID validation is active.
- Persistence now has an explicit environment gate, versioned profile schema,
  bounded retry wrapper, autosave, and shutdown save. Migration coverage and
  live DataStore behavior still require Studio validation.
- `ObbyService` uses a server Heartbeat for critical motion and bounded 10 Hz
  queries for wind and pressure pads; moving-platform rider correction remains
  a Studio physics validation item.
- Lighting and ambience are applied globally during generation; decoration uses
  a fixed world coordinate for every zone.
- Music and effects cycle through unverified hard-coded asset IDs.
- UI now has an initial state handshake, settings, mode, and basic accessibility
  controls; responsive device and gamepad behavior remain unverified.
- Server capacity configuration is now intentionally left to Creator Hub;
  unused Lua capacity knobs are not treated as effective settings.
- Automated confidence includes configuration, storyboard, production, Stylua,
  Selene, and CI Rojo-build gates; runtime traversal still requires Studio.

## Not claimed as tested

No Roblox Studio integration is available in this environment. Playability,
mobile/gamepad behavior, multiplayer physics, asset permissions, DataStore
behavior, frame rate, and Studio Output are therefore pending Studio execution.

## First implementation priorities

1. Stable stage/progression/ownership contracts and validation.
2. Server-authoritative profile and per-player collectible state.
3. Remote/state synchronization and safe development commands.
4. Performance and presentation improvements that can be verified locally.
