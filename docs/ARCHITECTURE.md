# Architecture

The server owns generated geometry, checkpoints, collectibles, completion, and
development commands. Clients own presentation only. `WorldBuilder` creates a
single `Workspace.GeneratedObby` tree marked with `GeneratorOwner`, the
canonical generator version, and seed attributes; rebuilds may remove only
that owned tree. The validator rejects an unsupported structural version, so a
seed is never mistaken for an identical layout after generator changes.

`StageBuilder` gives every stage a stable ID, entrance, exit, checkpoint, and
metadata including the chapter's primary mechanic, flavor, and difficulty tier.
It also returns an explicit gameplay path corridor with a center CFrame and
configured width, plus a bounded non-empty mechanics list used by presentation
and runtime diagnostics.
`ZoneBuilder` records each stage's measured connector length and owning zone as
it connects exits and entrances, so templates do not hide travel spacing.
`WorldBuilder` carries the previous zone exit into the next zone, including the
intentional elevation transition.
Its returned world manifest also exposes each zone's model, entrance, exit,
bounds, center, and index for presentation and inspection systems.
The same build gate validates zone count/order, generated-root ownership,
finite bounds, and inter-zone transition length.
Stable IDs and stage types are compared against the canonical configuration
before persistence-facing systems consume them.
`WorldValidator` checks those measurements and ownership before the world is
considered valid; each generated stage model also carries a matching
`ZoneIndex` marker so the manifest cannot claim ownership the instance does
not have; validation also checks that the stage is still parented to the
recorded zone container.

The current obstacle runtime remains centralized for compatibility, but the
new contracts make a later component split safe. Studio playtesting is required
before changing rider-carry physics or declaring cart reliability.

Development commands use server-owned `TextChatCommand` aliases when the modern
chat service is available, with a guarded legacy fallback for older test
places. They remain allowlisted outside Studio, parsed with anchored syntax,
bounded by seed/stage limits, and rate-limited. They are not a player
progression or reward API.

Checkpoint and key touches additionally require a live HumanoidRootPart,
positive Humanoid health, a short server-side distance bound, and contiguous
chapter order. These are sanity checks for authority, not a latency-punishing
anti-cheat system; Practice establishes its selected chapter as the temporary
starting point before the same forward sequence resumes.

Network names and payload direction are documented in
`src/shared/Network/RemoteContracts.lua`. Progress, keys, and finale messages
are server-to-client only; the client cannot award progression.

Pure checkpoint sequencing is isolated in `Util/ProgressionRules.lua`; the
server service supplies the authoritative current checkpoint and stage count.
This keeps the security rule independent of Roblox services and makes it
appropriate for a small standalone Luau test runner when one is available.

`EnvironmentController` owns local zone presentation and smoothly transitions
Lighting from chapter progress. The server still builds geometry and stores the
zone palette, but does not repeatedly overwrite global Lighting while building.

`SoundGroups` idempotently owns shared `Music`, `Ambience`, `SFX`, and `UI`
SoundGroup buses, so startup order cannot leave an early-created sound
unassigned.
Approved music, zone ambience, and client finale feedback route through those
buses, as do checkpoint and Golden Key feedback sounds, so future volume
controls do not require rewriting individual sounds.

Beacon bobbing is cosmetic-only: the runtime excludes parts carrying gameplay
tags or the explicit `PhysicsDecor` marker, so presentation animation cannot
fight moving-platform, hazard, gate, or constrained-physics systems.

World construction does not broadcast a fake Stage 0 state. A client requests
its authoritative restored state through `GetObbyState`, then receives later
server-owned progression events.

Progression events include the stable chapter ID as well as display text, so UI
and analytics consumers do not need to treat mutable labels as identity.

Finale presentation is player-specific: the server sends only the completing
player's finale event, while the client attaches local effects to that player's
character. Shared checkpoint objects do not emit a finale burst for everyone.

Golden Keys use the same split: the server records a stable `KeyId` per player,
while the client applies `LocalTransparencyModifier` to that player's collected
keys. The physical instance is never destroyed, so other players can collect
it independently.

Shutdown persistence is registered once at module scope and follows the active
checkpoint service across Studio rebuilds, preventing duplicate save callbacks.
