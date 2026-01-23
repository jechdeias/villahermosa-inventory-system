---
trigger: glob
globs: **/*api*.dart
---

- All API calls must be asynchronous.
- Handle timeouts and failures gracefully.
- Never assume successful responses.
- APIs must return explicit success or error states.
- UI must remain responsive during API calls.
