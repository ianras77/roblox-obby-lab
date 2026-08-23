# Analytics

The server-only, no-op-safe event set is implemented through
`Services/AnalyticsService.lua`; it remains disabled by default until a
telemetry destination and policy are approved:

| Event | Trigger | Decision it informs |
| --- | --- | --- |
| `joined` | PlayerAdded | Load and onboarding reliability |
| `chapter_started` | First valid progress in a chapter | Pacing and drop-off |
| `chapter_completed` | Monotonic checkpoint | Difficulty and completion |
| `golden_key_discovered` | First valid key ID per player | Exploration value |
| `run_completed` | Final checkpoint once per run | Finish and replay rate |

Do not log chat, raw payloads, or high-cardinality personal data.

Implementation status: the wrapper is disabled in Studio and by default. When
explicitly enabled in a non-Studio environment, it submits the allowlisted
events through Roblox `AnalyticsService:LogCustomEvent` inside `pcall`, using a
fixed low-cardinality value of `1`.
