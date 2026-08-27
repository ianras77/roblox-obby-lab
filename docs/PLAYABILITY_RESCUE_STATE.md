# Playability Rescue State

- Branch: `codex/toads-great-escape-next-level`
- Base commit: `fd2e263`
- Phase: phase 3 structural validation and mechanic declarations
- Completed tasks: branch/worktree verified; rescue state initialized; generic cart spawning removed; period-based moving motion added; explicit forward conveyor declarations added; bounded wind added; forgiving Adventure obstacle defaults added; course-floor helper added; long floors repaired for Toad Hall, Library, and Jailbreak; stable required-route anchors added to all 18 definitions; validator now checks route shape, landing floors, conveyor direction, moving-platform period/velocity, and falling delays; timed hazards now synchronize CanTouch with visibility
- Verified findings: legacy aggressive obstacle defaults and ambiguous `Speed` mechanics were present; stage templates include known floor/conveyor/train/wind audit targets
- Unresolved blockers: Studio/device/multiplayer evidence not yet available; `luau` and `rojo` are unavailable in this environment; train state machine, assist mode, route physical connectivity, and device tests remain
- Tests run: `scripts/config_contract.sh`; `stylua`; `git diff --check`
- Tests passed: config contract; Stylua; whitespace check
- Studio tests performed: none
- Studio tests still required: isolated five-pass chapter QA, three full runs, mobile, gamepad, two-player, Output/performance review
- Exact next action: add local playability contract tests and complete train/cart/hazard safety fixes that can be proven without Studio
