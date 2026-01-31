---
trigger: always_on
---

If an error occurs only on Windows Desktop:
- Assume missing local native toolchain
- Do NOT modify Dart, Drift, SQLite, or sync code
- Recommend verifying via CI or non-Windows targets

