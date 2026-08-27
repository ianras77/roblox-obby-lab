# Playability Rescue State

- Branch: `codex/toads-great-escape-next-level`
- Base commit: `fd2e263`
- Phase: phase 1 runtime tuning foundation
- Completed tasks: branch/worktree verified; rescue state initialized; generic cart spawning removed; period-based moving motion added; explicit forward conveyor default added; bounded wind added; forgiving Adventure obstacle defaults added
- Verified findings: legacy aggressive obstacle defaults and ambiguous `Speed` mechanics were present; stage templates include known floor/conveyor/train/wind audit targets
- Unresolved blockers: Studio/device/multiplayer evidence not yet available; `luau` and `rojo` are unavailable in this environment; geometry contract, required routes, hazards, train, assist mode, and tests remain
- Tests run: `./scripts/check.sh` (blocked at missing luau); `rojo build` (blocked: command unavailable); `stylua` and `git diff --check`
- Tests passed: contracts before Luau invocation; Stylua; whitespace check
- Studio tests performed: none
- Studio tests still required: isolated five-pass chapter QA, three full runs, mobile, gamepad, two-player, Output/performance review
- Exact next action: implement explicit stage geometry helpers and required-route metadata, beginning with canonical floor/exit placement and validator contracts
