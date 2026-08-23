# Performance baseline and plan

No Roblox MicroProfiler or device frame-time measurements are available in the
current environment. The known high-cost paths are the global Heartbeat, rider
`GetTouchingParts`, bounded wind/pressure queries, per-frame transforms,
and permanent particle emitters. Studio profiling must measure generation,
join, chapters 10/12/13/15/18, and a two-player session before release.

Wind and pressure-pad contact queries are bounded to a 10 Hz server tick, and
moving-platform rider sampling is bounded to a 20 Hz server tick. The obstacle
transforms remain centralized, while rotators, gavel animation, and timed-tile
state updates are bounded to a 30 Hz server tick. Moving-platform transforms
and critical hazard authority remain on the Heartbeat path and need Studio
profiling before proximity sleeping or a component split is declared safe.

Planned work: proximity activation, bounded spatial checks, sleeping distant
mechanics, pooled effects, anchored scenery, and explicit collision/query
flags. No frame-rate claim is made here.

Non-critical rotators, gavel presentation, timed-tile visuals, and beacons now
activate only within 180 studs of a live player. Timed-tile phase still advances
while asleep so reactivation is deterministic; critical hazards and transport
remain active and server-authoritative.

The world validator also reports unanchored generated environment parts, while
allowing intentional cart ride assemblies. Static scenery should remain
anchored to avoid accidental server physics and replication cost.

Humanoid death connections are tracked per player and replaced on each new
character, preventing respawn cycles from accumulating listeners in the service
Maid.
Kill-brick debounce tables use weak Humanoid keys so defeated character
instances do not accumulate indefinitely in long-lived obstacle connections.

Cart behavior now has a 45-second timeout and below-course recovery reset;
boarding, dismounting, multiplayer interaction, and high-latency behavior still
require Studio playtesting before the cart is called production-ready.
