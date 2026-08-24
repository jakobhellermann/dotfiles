---
description: Disposable sipgate dev test accounts (1127298 DE, 1127337 UK) with declarative provisioning. Use when setting up or changing test resources on these playground accounts, or when performing call tests with the baresip MCP.
---

# ai-playground-account

- Repo: `~/dev/me/ai-playground-account` — Details stehen im dortigen `AGENTS.md`.
- Accounts: 1127298 (DE, `api.dev.sipgate.com`), 1127337 (UK); Resourcen dort dürfen frei erstellt/geändert werden.
- Setup ist deklarativ in `provision/src/Playground{De,Uk}.kt` (Kotlin-DSL `account-provisioning`) — Änderungen dort machen, dann `scripts/provision de|uk apply` (`--dry` zeigt den Diff).
- Aktueller Ist-Zustand inkl. SIP-Credentials liegt nach jedem Lauf frisch in `inventory/<acct>/topology.json`.
- Alles dort darf nach freier Verfügung verändert werden (Setup erweitern, Resourcen löschen, etc.).
