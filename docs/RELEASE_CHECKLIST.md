# Release checklist

- [ ] Rojo build, Stylua, Selene, validator, and pure tests pass.
- [ ] CI produces a valid Rojo place artifact from `default.project.json` using
      the pinned official Rojo release binary.
- [ ] Superseded branch CI runs are cancelled by workflow concurrency.
- [ ] Studio full run and multiplayer run have evidence.
- [ ] Creator Hub max players, supported devices, icon, thumbnails, badges,
      private staging place, and approved audio are configured.
- [ ] Production DataStore name and environment separation are verified.
- [ ] `GameConfig.Environment` and `UseDataStore` match the intended place;
      Studio production writes are blocked.
- [ ] No serious Output errors; no unverified asset IDs remain.
- [ ] Branch reviewed and merged by an owner; Roblox publication remains manual.
