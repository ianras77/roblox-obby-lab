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

`GameConfig.Environment` is an explicit deployment label. The development
environment cannot write production data; staging and production must use
distinct configured store names. The checkpoint service now autosaves on the
configured interval and saves on shutdown/player removal.

Persistence is enabled by default. `StudioDevelopment` remains fail-closed in
the wrapper; use a distinct `StudioSandbox` store name and a deliberate place
configuration when testing persistence in Studio.

Profile updates merge monotonic chapter/death/completion values, union collected
keys, and retain the fastest valid run inside `UpdateAsync` so concurrent saves
do not overwrite progress.

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

Accessibility settings use the validated `SetAccessibilitySettings` contract;
this includes `showTimer`, which only changes local timer presentation and
never changes server-owned timing.
six boolean keys are accepted and writes are rate-limited before entering
the profile.

Fresh profiles initialize all six supported accessibility booleans; legacy
profiles preserve only validated boolean values and a bounded UI scale.

Profile sanitization migrates the original `checkpoint` field into
`highestChapter` and rejects implausible timing values rather than silently
wiping valid legacy progress.
