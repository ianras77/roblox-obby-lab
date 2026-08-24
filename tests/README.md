# Tests

This folder contains pure-Luau tests that do not require Roblox services. CI
installs the pinned Luau 0.734 runner and executes them through scripts/check.sh.
Roblox-only behavior is still explicitly tracked as pending rather than
reported as green.

The current storyboard, production, and canonical configuration contracts run
from `scripts/` so `scripts/check.sh` works in the shared Roblox toolchain
container without adding a Luau test framework.
## Test status

The repository's executable confidence gates are the configuration, profile,
storyboard, and production contract scripts plus Stylua/Selene and the CI Rojo
build. Roblox-only behavior still requires Studio execution using
`docs/PLAYTEST_MATRIX.md`.

The server-side validator runs during world generation and reports invalid stage
manifests without deleting user-owned Workspace content.
