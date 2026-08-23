# Performance baseline and plan

No Roblox MicroProfiler or device frame-time measurements are available in the
current environment. The known high-cost paths are the global Heartbeat, rider
`GetTouchingParts`, bounded wind/pressure queries, per-frame transforms,
and permanent particle emitters. Studio profiling must measure generation,
join, chapters 10/12/13/15/18, and a two-player session before release.

Wind and pressure-pad contact queries are now bounded to a 10 Hz server tick;
the remaining moving-platform rider query is still per-frame and needs Studio
profiling before replacement.

Planned work: proximity activation, bounded spatial checks, sleeping distant
mechanics, pooled effects, anchored scenery, and explicit collision/query
flags. No frame-rate claim is made here.

The world validator also reports unanchored generated environment parts, while
allowing intentional cart ride assemblies. Static scenery should remain
anchored to avoid accidental server physics and replication cost.

Cart behavior now has a 45-second timeout and below-course recovery reset;
boarding, dismounting, multiplayer interaction, and high-latency behavior still
require Studio playtesting before the cart is called production-ready.
