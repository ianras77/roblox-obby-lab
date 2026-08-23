# Data model

The current profile is versioned and server-owned:

```lua
{ schemaVersion = 1, highestChapter = 0, collectedKeys = {},
  bestRunMs = nil, bestChapterMs = {}, totalDeaths = 0,
  completionCount = 0, settings = {} }
```

The implementation includes validated migrations, `UpdateAsync`, bounded retry
backoff, autosave, `PlayerRemoving`, `BindToClose`, and separate Studio
sandbox/private staging/production store naming. Live Roblox verification is
still required before release.

If a profile read fails, the player receives a sanitized ephemeral profile and
may continue playing for that session. The service does not write that profile
back unless the read succeeded, preventing an outage from overwriting stored
progress. The load/save diagnostic attributes expose this distinction.

`GameConfig.Environment` is an explicit deployment label. The development
environment cannot write production data; staging and production must use
distinct configured store names. The checkpoint service now autosaves on the
configured interval and saves on shutdown/player removal.

Persistence is enabled by default. `StudioDevelopment` remains fail-closed in
the wrapper; use a distinct `StudioSandbox` store name and a deliberate place
configuration when testing persistence in Studio. `StudioDevelopment` is
ephemeral, `StudioSandbox` uses a suffixed store when Studio API access is
enabled, and unknown environments fail closed. Live `Production` persistence
is blocked when running inside Studio.

Profile updates merge monotonic chapter/death/completion values, union collected
keys, and retain the fastest valid run inside `UpdateAsync` so concurrent saves
do not overwrite progress.

Settings are sanitized per session and the latest completed save supplies the
preference snapshot; they are not treated as progression counters.

Run state is server-owned and distinguishes `Adventure`, `TimeTrial`, and
`Practice`. Practice completion is deliberately ineligible for a time-trial
score. Timing and leaderboard submission still require Studio validation.

Selecting Adventure for a replay clears only the live checkpoint and run
position; persisted highest progress and Golden Keys are retained.

Qualifying final-chapter completion updates `completionCount` on the server;
only an eligible Time Trial completion updates the smallest `bestRunMs`.
Character deaths increment `totalDeaths`; Adventure and Practice completion do
not overwrite the Time Trial personal best.

Time Trial chapter splits update `bestChapterMs` only when they improve the
stored split; Adventure and Practice do not submit leaderboard-style splits.
Split keys are bounded to the canonical 18-chapter route during profile
sanitization and concurrent datastore merging.

Keys are authored deterministically at chapter locations (one per chapter in
the current configuration), and the client requests initial HUD state through
`GetObbyState` instead of depending solely on a startup event.

The server exposes non-authoritative diagnostics through player attributes:
`ProfileLoadStatus` is `Loading`, `Ready`, or `Failed`; `ProfileSaveStatus` is
`Saved`, `Skipped`, or `Failed`; and `ProfileSavedAt` records the last successful save's
Unix timestamp. These attributes are for operator diagnostics, not client
permission or progression decisions.

Accessibility settings use the validated `SetAccessibilitySettings` contract;
this includes `showTimer`, which only changes local timer presentation and
never changes server-owned timing.
six boolean keys are accepted and writes are rate-limited before entering
the profile.

`masterVolume`, `musicVolume`, and `sfxVolume` are validated numbers from 0 to
1. They change only the local SoundGroup mix and never alter shared gameplay.
`uiScale` is validated from 0.8 to 1.5 and is applied locally to the HUD.
Concurrent saves preserve valid numeric settings from the existing record.

Fresh profiles initialize all six supported accessibility booleans; legacy
profiles preserve only validated boolean values and a bounded UI scale.

Profile sanitization migrates the original `checkpoint` field into
`highestChapter` and rejects implausible timing values rather than silently
wiping valid legacy progress.
