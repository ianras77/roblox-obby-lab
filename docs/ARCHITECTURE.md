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

Network names and payload direction are documented in
`src/shared/Network/RemoteContracts.lua`. Progress, keys, and finale messages
are server-to-client only; the client cannot award progression.

`EnvironmentController` owns local zone presentation and smoothly transitions
Lighting from chapter progress. The server still builds geometry and stores the
zone palette, but does not repeatedly overwrite global Lighting while building.
