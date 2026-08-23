# Playtest matrix

Pending Roblox Studio execution: fresh run, returning profile, mobile portrait
and landscape, tablet, desktop, gamepad, two players, late join, reset during a
cart/finale, DataStore failure, missing asset, reduced motion, high contrast,
large UI, low particles, and muted audio. Record build seed, device, Studio
Output errors, chapter reached, and reproducible failure details for each run.

The settings panel is now present in the client HUD. Verify each toggle changes
the corresponding effect, survives respawn, and is migrated into the server
profile before release.

Replay controls now expose Adventure, Time Trial, and Practice from the HUD;
verify mode reset timing, checkpoint semantics, completion results, and that no
Practice run can qualify for a leaderboard.
