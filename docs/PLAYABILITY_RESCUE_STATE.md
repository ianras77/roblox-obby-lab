# Playability Rescue State

- Branch: `codex/toads-great-escape-next-level`
- Base commit: `fd2e263`
- Phase: phase 2 geometry contract foundation
- Completed tasks: branch/worktree verified; rescue state initialized; generic cart spawning removed; period-based moving motion added; explicit forward conveyor default added; bounded wind added; forgiving Adventure obstacle defaults added; course-floor helper added; long floors repaired for Toad Hall, Library, and Jailbreak; stable required-route anchors added to all 18 definitions
- Verified findings: legacy aggressive obstacle defaults and ambiguous `Speed` mechanics were present; stage templates include known floor/conveyor/train/wind audit targets
- Unresolved blockers: Studio/device/multiplayer evidence not yet available; `luau` and `rojo` are unavailable in this environment; route connectivity validation, hazards, train, assist mode, and tests remain
- Tests run: `./scripts/check.sh` (blocked at missing luau); `rojo build` (blocked: command unavailable); `stylua`; `scripts/config_contract.sh`; `git diff --check`
- Tests passed: existing shell contracts before Luau invocation; config contract; Stylua; whitespace check
- Studio tests performed: none
- Studio tests still required: isolated five-pass chapter QA, three full runs, mobile, gamepad, two-player, Output/performance review
- Exact next action: add fail-closed playability validation and regression tests for route support, motion caps, explicit mechanics, hazards, and authored carts
