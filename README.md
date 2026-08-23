# Toad's Great Escape Obby

A procedural Roblox obby inspired by the public-domain book world of **The Wind in the Willows**. Press Play and the server builds an 18-chapter storybook run through riverbank jumps, Toad Hall, runaway roads, courtroom trouble, jail escape, Wild Wood, and a fireworks homecoming.

The goal is for kids to play it, laugh at the chaos, then open the configs and remix it.

## Quick start

If you are using the shared studio workspace:

```bash
cd /data/roblox
./scripts/studio serve obby-of-legends
```

If you are working directly inside this repo with local tools installed:

```bash
./scripts/dev.sh
./scripts/check.sh
./scripts/rojo_serve.sh
```

## Windows Studio bridge

1. Install the Rojo plugin in Roblox Studio on Windows.
2. Make sure Windows can reach your Linux host on port `34872`.
3. In the Rojo plugin, connect to `http://<linux-host-ip>:34872`.
4. Publish to your Roblox account manually from Studio when ready.

## Storyboard

1. Riverbank Welcome
2. Mole's Burrow Bounce
3. Ratty's River Stones
4. Toad Hall Gate
5. Library Tumble
6. Runaway Caravan
7. Tavern Barrel Hop
8. Courtroom Chaos
9. Jailbreak Bars
10. Laundry Cart Escape
11. Barge Crossing
12. Train Tunnel Dash
13. Wild Wood Gusts
14. Badger's Lantern Path
15. Motorcar Madness
16. Roadside Cone Sprint
17. Homecoming Ring Run
18. Toad Hall Fireworks

## Project layout

```text
roblox-obby-lab/
  src/
    client/
    server/
    shared/
    workspace/
  tests/
  scripts/
  default.project.json
```

## Scripts

- `scripts/dev.sh` prints the local tool versions and confirms the project file.
- `scripts/check.sh` runs the storyboard and production contracts, `stylua --check`, and `selene`.
- `scripts/rojo_serve.sh` starts a Rojo server on the port declared in `default.project.json`.

## Notes

- Kid-friendly tuning notes live in `README_KIDS.md`.
- The original build spec for this project lives in `SPEC.md`.
- CI runs contracts, formatting, linting, and a pinned Rojo place build from
  `.github/workflows/ci.yml`.
- The generated world is owned by `Workspace.GeneratedObby`; the seed and
  generator version are recorded on that model. See `docs/AUDIT.md` and
  `docs/IMPLEMENTATION_LOG.md` for verified status and Studio-only checks.
