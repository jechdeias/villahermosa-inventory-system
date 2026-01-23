---
trigger: glob
globs: **/*database*.dart
---

- SQLite is the source of truth when offline.
- Every table must include:
  - Local unique ID
  - Sync status (pending, synced, conflict)
  - created_at and updated_at timestamps
- Never overwrite synced data without tracking changes.