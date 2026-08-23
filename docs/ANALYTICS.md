# Analytics

Analytics is not enabled yet. The planned server-only, no-op-safe event set is:

| Event | Trigger | Decision it informs |
| --- | --- | --- |
| `joined` | PlayerAdded | Load and onboarding reliability |
| `chapter_started` | First valid progress in a chapter | Pacing and drop-off |
| `chapter_completed` | Monotonic checkpoint | Difficulty and completion |
| `golden_key_discovered` | First valid key ID per player | Exploration value |
| `run_completed` | Final checkpoint once per run | Finish and replay rate |

Do not log chat, raw payloads, or high-cardinality personal data.
