---
trigger: model_decision
description: Apply when handling order creation, updates, or delivery logic.

- Order booking
- Delivery preparation
- Order cancellation
---

- Track order status (Pending, Prepared, Delivered).
- Cancellations must reverse stock if applicable.
- Delivered orders are locked and immutable.
