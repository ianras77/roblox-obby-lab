# Architecture

The server owns generated geometry, checkpoints, collectibles, completion, and
development commands. Clients own presentation only. `WorldBuilder` creates a
single `Workspace.GeneratedObby` tree marked with `GeneratorOwner`, version,
and seed attributes; rebuilds may remove only that owned tree.

`StageBuilder` gives every stage a stable ID, entrance, exit, checkpoint, and
metadata including the chapter's primary mechanic, flavor, and difficulty tier.
`ZoneBuilder` connects exits and entrances, so templates do not also
hide travel spacing. `WorldValidator` checks the generated manifest before the
world is considered valid.

The current obstacle runtime remains centralized for compatibility, but the
new contracts make a later component split safe. Studio playtesting is required
before changing rider-carry physics or declaring cart reliability.

Development chat commands are allowlisted outside Studio, parsed with anchored
syntax, bounded by seed/stage limits, and rate-limited. They are not a player
progression or reward API.

Checkpoint and key touches additionally require a live HumanoidRootPart,
positive Humanoid health, and a short server-side distance bound. These are
sanity checks for authority, not a latency-punishing anti-cheat system.

Network names and payload direction are documented in
`src/shared/Network/RemoteContracts.lua`. Progress, keys, and finale messages
are server-to-client only; the client cannot award progression.

`EnvironmentController` owns local zone presentation and smoothly transitions
Lighting from chapter progress. The server still builds geometry and stores the
zone palette, but does not repeatedly overwrite global Lighting while building.

World construction does not broadcast a fake Stage 0 state. A client requests
its authoritative restored state through `GetObbyState`, then receives later
server-owned progression events.

Finale presentation is player-specific: the server sends only the completing
player's finale event, while the client attaches local effects to that player's
character. Shared checkpoint objects do not emit a finale burst for everyone.

Shutdown persistence is registered once at module scope and follows the active
checkpoint service across Studio rebuilds, preventing duplicate save callbacks.
