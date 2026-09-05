# Playability audit — 2026-09-05

Source inspection, not Studio evidence. Audited main b0af18b; starting checkout e8cd5c4 on codex/toads-great-escape-next-level. Main remains at the audited baseline after fetch. Production branch preserves newer commits. Incoming uncommitted conveyor patch saved to /tmp/obby-incoming.patch; its Y-preservation intent is retained, direction reconciled to +X.

Baseline: git status --short reported one modified ObbyService.lua. ./scripts/check.sh passed four shell contracts then failed: luau: command not found. git diff --check passed. Rojo absent from PATH at baseline.

Confirmed remaining source defects: zone elevation has no constructed connector; route anchors are generic metadata with no geometry support tests; Build.part discards collision/visibility properties; duplicate startup; conveyor touch writes replace steering; wind dedupe absent; moving rider dedupe resets per platform; inactive hazards can still kill; lasers become collidable; Beacon conflicts and constraint decorations; falling platforms have no warning; Reset kills locally; no adaptive assistance; disabled skip UI; staging store shares production namespace; rebuild loses in-memory profiles; analytics start/complete emitted together. UI has fixed competing controls, zero totals, and semantic hazard recoloring.

Earlier branch work already addresses personal key claims, sequential monotonic checkpoints, initial snapshot handshake, UpdateAsync schema merges/autosave/close, personal finale, bounded spatial queries, and local environment presentation. These are retained and strengthened.

Performance risks: replicated cosmetic CFrame loops, continuous emitters, expensive scene-wide accessibility scans, unprofiled scenery. No Studio, device, multiplayer, network or human tests have been run. Static contract scripts alone cannot prove playability. New pure geometry tests and opt-in Studio harness provide separate evidence gates.

Final implementation replaces unsafe canonical templates with a fixed supported spine and visible optional lessons, preserving old artwork outside production plus existing zone landmarks. Timed hazards use root-volume sampling because Roblox CanTouch=false disconnects/forbids touch listeners. The runtime validator and isolated Studio mutation harness are implemented but have not been executed in Roblox. See VERIFICATION.md for the exact final local output and the limits of each evidence type.
