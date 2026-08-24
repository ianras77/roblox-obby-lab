# Release checklist

- [x] Local configuration, storyboard, production, and Stylua checks pass.
- [ ] Selene and pure runtime tests pass in a local toolchain; Selene is not
      installed in this environment.
- [x] CI produces a valid Rojo place artifact from `default.project.json` using
      the pinned official Rojo release binary.
- [x] CI uses pinned official release binaries for Stylua and Selene.
- [x] Superseded branch CI runs are cancelled by workflow concurrency.
- [x] CI checkout action uses the Node 24-compatible release line.
- [ ] Studio full run and multiplayer run have evidence.
- [ ] Creator Hub max players, supported devices, icon, thumbnails, badges,
      private staging place, and approved audio are configured.
- [ ] Creator Hub owns the actual maximum-player setting; no Lua config is
      treated as a substitute for that dashboard value.
- [ ] Production DataStore name and environment separation are verified.
- [ ] `GameConfig.Environment` and `UseDataStore` match the intended place;
      Studio production writes are blocked.
- [ ] No serious Output errors; asset IDs are Creator Hub-verified and approved.
- [ ] Branch reviewed and merged by an owner; Roblox publication remains manual.
