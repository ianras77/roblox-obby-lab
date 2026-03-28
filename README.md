# Roblox Obby Lab

Procedural Roblox obby project with a Rojo-first workflow. This repo now lives inside the shared `/data/roblox` studio workspace, but it is also clean enough to stand on its own as a separate Git repo.

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

## Project layout

```text
roblox-obby-lab/
  src/
    client/
    server/
    shared/
    workspace/
  assets/
  place/
  tests/
  scripts/
  default.project.json
```

## Scripts

- `scripts/dev.sh` prints the local tool versions and confirms the project file.
- `scripts/check.sh` runs `stylua --check` and `selene`.
- `scripts/rojo_serve.sh` starts a Rojo server on the port declared in `default.project.json`.

## Notes

- Kid-friendly tuning notes live in `README_KIDS.md`.
- The original build spec for this project lives in `SPEC.md`.
- CI runs formatting and lint checks from `.github/workflows/ci.yml`.
