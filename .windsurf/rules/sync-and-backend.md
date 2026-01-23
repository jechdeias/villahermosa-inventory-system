---
trigger: model_decision
description: Apply when implementing sync logic or backend communication.
- Uploading offline data
- Resolving conflicts
- Cloud synchronization logic
---

- Queue offline actions.
- Sync automatically when connection is restored.
- Use timestamp-based conflict detection.
- Apply last-write-wins by default.
- Log conflicts for admin review.
- Sync must never block the UI.