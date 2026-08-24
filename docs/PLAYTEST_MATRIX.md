# Playtest matrix

Pending Roblox Studio execution: fresh run, returning profile, mobile portrait
and landscape, tablet, desktop, gamepad, two players, late join, reset during a
cart/finale, DataStore failure, missing asset, reduced motion, high contrast,
large UI, low particles, and muted audio. Record build seed, device, Studio
Output errors, chapter reached, and reproducible failure details for each run.

The settings panel is now present in the client HUD. Verify each toggle changes
the corresponding effect, survives respawn, and is migrated into the server
profile before release.

High contrast must visibly distinguish tagged hazards from the safe route, and
Low particles must leave gameplay-critical readability intact while disabling
ambient emitters.

Also verify that emitters created by a development rebuild or streamed-in
content inherit the current low-particles setting.

Reduced Motion must preserve the completion cue and results flow while omitting
finale fireworks and spotlight animation; verify this in Studio alongside the
normal celebration path.

Flash reduction must additionally suppress finale blur, color correction,
spotlight, and local firework bursts while retaining audio and results.

Replay controls now expose Adventure, Time Trial, and Practice from the HUD;
verify mode reset timing, checkpoint semantics, completion results, and that a
Practice run never qualifies for a leaderboard or personal best.

Also verify that Adventure replay completion unlocks Time Trial but does not
replace the stored Time Trial personal best.

Completion results must distinguish route completion from Golden Key exploration
percentage, including the zero-key case.

Also verify a new player cannot activate Time Trial, and that it becomes
available only after an Adventure completion.

For generated-world ownership, add a tagged key outside `Workspace.GeneratedObby`
and confirm it does not change the HUD total, results exploration percentage, or
server analytics. Deliberately alter a generated key's `StageIndex` and confirm
`WorldValidator` rejects the build.

For active mechanics, profile moving-platform riders, wind zones, and pressure
pads with two clients while checking that overlap results remain bounded and
that players are still detected when decorative parts overlap the query volume.

Reset and death should clear residual velocity before safe-spawn teleport; test
this at moving platforms, carts, and hazards.

The Results Replay action must return the player to the start without reducing
saved unlock progress or collected keys.

On a narrow phone portrait viewport, verify the settings panel remains usable
through scrolling and that mode, setting, volume, and practice controls retain
at least the shared 44px touch target height.
