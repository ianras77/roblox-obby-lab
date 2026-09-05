# Analytics plan

Implementation: server-only `AnalyticsService.lua`; APIs checked against the [Roblox AnalyticsService reference](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService). Analytics is explicitly off in GameConfig and never sends from Studio. No secrets or Dashboard changes are needed to play.

| Stream | Trigger | Dedupe |
| --- | --- | --- |
| JoinedGame | profile initialization | once per connection |
| FirstMovement | server observes humanoid movement | once per connection |
| FirstCheckpoint | chapter 1 completion | once per connection |
| Stage3Complete | chapter 3 completion | once per connection |
| StoryComplete | chapter 18 completion | once per connection |
| MainStory Start | current chapter initialized / retry | 0.5-second per-key bound |
| MainStory Fail | accepted reset, fall or active hazard | player recovery debounce |
| MainStory Complete | sequential checkpoint accepted | once per chapter per run |
| AssistActivated | personal grace/help used | once per chapter per run |
| SkipUsed | server accepts opt-in Help | once per chapter per run |
| StageDuration | chapter completion | once per chapter per run |
| StoryCompleteDuration | eligible story completion | once per run |
| CollectibleFound | personal server claim | once per chapter per run |

Progression path is `MainStory`, level is 1–18, level name is the canonical chapter name. Custom event names never contain a chapter suffix. The three custom fields are bounded stage number, assisted yes/no, and story/challenge route category. No player text, key ID, device fingerprint or position is logged. The input category is intentionally not inferred from untrusted client claims.

The wrapper contains delivery errors, limits to 100 events/player/minute, and preserves funnel dedupe across replay. Studio exercises its state without delivery. Network delivery and dashboard appearance remain unverified. Time values are seconds; saved profile best times are milliseconds. Stage duration includes retries and the incoming connector. Loaded profiles begin measuring only the resumed session, not earlier sessions.

Dashboard questions: Where do first-time players stop? Does chapter 3 retain at least 90%? Do assistance recipients recover and finish? Which optional mechanics cause resets? Does playtime approach 8–12 minutes? Does a second run attract exploration? Compare completion and duration before tightening gaps or increasing motion. Targets are hypotheses, not measured achievements. Distinguish resume, replay and test traffic during private testing; don't enable production analytics before validating staging events.
