# Data model

The current release still uses checkpoint-only persistence and is intentionally
not claimed as production-ready. The target profile is versioned and server
owned:

```lua
{ schemaVersion = 1, highestChapter = 0, collectedKeys = {},
  bestRunMs = nil, bestChapterMs = {}, totalDeaths = 0,
  completionCount = 0, settings = {} }
```

Before release, implement validated migrations, `UpdateAsync`, bounded retry
backoff, autosave, `PlayerRemoving`, `BindToClose`, and separate Studio
sandbox/private staging/production stores.

`GameConfig.Environment` is an explicit deployment label. The development
environment cannot write production data; staging and production must use
distinct configured store names. The checkpoint service now autosaves on the
configured interval and saves on shutdown/player removal.

Run state is server-owned and distinguishes `Adventure`, `TimeTrial`, and
`Practice`. Practice completion is deliberately ineligible for a time-trial
score. Timing and leaderboard submission still require Studio validation.
