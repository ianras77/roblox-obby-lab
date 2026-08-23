# Tests

This folder contains the current test notes and the remaining pure-Luau test
entry point. A Roblox test runner is not installed in this environment, so
runtime tests are explicitly tracked as pending rather than reported as green.

The current storyboard, production, and canonical configuration contracts run
from `scripts/` so `scripts/check.sh` works in the shared Roblox toolchain
container without adding a Luau test framework.
## Test status

The repository's executable confidence gates are the storyboard and production
contract scripts plus Stylua/Selene and the CI Rojo build. Roblox-only behavior
still requires Studio execution using `docs/PLAYTEST_MATRIX.md`.

The server-side validator runs during world generation and reports invalid stage
manifests without deleting user-owned Workspace content.
