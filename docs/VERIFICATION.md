# Verification evidence — 2026-09-05

Working branch: `codex/production-playability`. Starting HEAD: `e8cd5c484cb6dd606386966fa1dd3b541e445968`; main/origin-main after fetch: `b0af18b1ab0cd819b5d1f0537476a22aa22e3046`. Main is an ancestor; no reset or force push. The incoming ObbyService conveyor diff was preserved in `/tmp/obby-incoming.patch` before implementing its Y-preservation intent with required +X direction.

Baseline commands:

- `git status --short`: ` M src/server/Services/ObbyService.lua`
- `git rev-parse HEAD`: `e8cd5c484cb6dd606386966fa1dd3b541e445968`
- `rg --files ...`: inspected source, scripts, tests, configs, Rojo project and CI.
- `./scripts/check.sh`: four shell contracts passed, then `luau: command not found`.
- `git diff --check`: exit 0, no output.
- `command -v rojo`: absent initially. After obtaining the CI-pinned tools, `rojo build /tmp/obby-original/default.project.json -o /tmp/obby-original.rbxlx` built an archived copy of the original HEAD successfully.

Tools were downloaded into `/tmp/obby-tools` using the repository CI versions: Luau 0.734, StyLua 2.3.1, Selene 0.29.0, Rojo 7.4.4. Initial sandbox DNS failure was resolved through approved network execution. No system toolchain installation or secret was required.

Final verification commands:

```sh
/tmp/obby-tools/stylua --check src tests
PATH=/tmp/obby-tools:$PATH ./scripts/check.sh
/tmp/obby-tools/rojo build default.project.json -o /tmp/toads-production-playability.rbxlx
/tmp/obby-tools/rojo build studio-test.project.json -o /tmp/toads-studio-tests.rbxlx
git diff --check
```

Successful check output:

```text
campaign: 18 definitions; metadata, route budgets and invalid-route mutations passed
source wiring: route, one startup, player ownership, rebuild, state, persistence and UI passed
movement/assist: Y, forward, steering, frame rates, period, phases, help thresholds, property contract passed
Build property application tests passed
hazard activation tests passed
config contract ok: 18 unique ordered chapters with matching metadata
profile contract ok: defaults, migration, bounds, settings, and key cap
progression rules tests passed
profile schema tests passed (including concurrent monotonic merges)
run rules tests passed
asset registry tests passed
Results:
0 errors
0 warnings
0 parse errors
Building project 'roblox-obby-lab'
Built project to toads-production-playability.rbxlx
Building project 'roblox-obby-lab'
Built project to toads-studio-tests.rbxlx
```

Whitespace and formatting checks produced no output on success. Early development checks exposed floating-point test precision, stale string-matching contracts, formatter normalization, and lint issues; these were corrected and rerun. The final API review also replaced timed-hazard Touched listeners with bounded root-volume sampling: toggling CanTouch disconnects touch listeners, as documented in [Roblox BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart).

Evidence boundary: Luau tests execute numeric route planning, invalid-route mutations, property application, movement math, assistance thresholds, progression rules, schema merges, run rules and assets. Python checks inspect service wiring. Rojo packages source; it does not execute Roblox runtime generation. Neither these checks nor the Studio harness source prove physical traversal, actual raycast results, UI fit or multiplayer behavior.

No RobloxStudio binary or running Roblox Studio process was available. The shared `/data/roblox/scripts/studio` helper is a Docker/Rojo tooling wrapper, not a graphical playtest API. No Studio, device, multiplayer, network emulation, performance or human playtest was run. No CI run was triggered remotely, no branch was pushed, no experience was published, and no Creator Dashboard setting was changed.

See PLAYTEST_MATRIX for all outstanding runtime rows. Release decision remains NOT READY until those gates are evidenced. The broad optional-detour design and 600-second authored novice-time hypothesis especially require real child-friendly playtesting.
