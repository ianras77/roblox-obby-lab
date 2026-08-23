# Performance baseline and plan

No Roblox MicroProfiler or device frame-time measurements are available in the
current environment. The known high-cost paths are the global Heartbeat, rider
`GetTouchingParts`, wind queries, pressure-pad queries, per-frame transforms,
and permanent particle emitters. Studio profiling must measure generation,
join, chapters 10/12/13/15/18, and a two-player session before release.

Planned work: proximity activation, bounded spatial checks, sleeping distant
mechanics, pooled effects, anchored scenery, and explicit collision/query
flags. No frame-rate claim is made here.
