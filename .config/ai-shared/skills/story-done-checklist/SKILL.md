---
name: story-done-checklist
description: Verifiziert vor dem Öffnen eines PRs, dass eine Feature-Implementierung wirklich fertig ist — adversarialer Code-Review aller geänderten Dateien, Pattern-Konformität & Vereinfachung, Tests rot-then-grün validiert, Deployment-Sicherheit (Migrations, Kafka, Config, Rolling Deploy). Use wenn eine Story implementiert ist und vor dem PR geprüft werden soll.
argument-hint: <geänderte Dateien / Branch | optional JIRA-KEY>
---

# Story-Done Checklist

Run this when asked to verify a feature implementation is truly done before opening a PR.

## 1. Adversarial Code Review

Read every changed file end-to-end. For each, ask:

- **What can go wrong at runtime?** — null/missing DB rows, race conditions, partial failures, exception swallowing
- **What assumptions are unstated?** — implicit ordering, default values that mask bugs, silent fallbacks
- **Does the error path match the happy path's cleanup?** — if the happy path opens a resource, does the error path close it?
- **Are there half-measures left in the code?** — TODOs, commented-out code, `// handled later`, unreachable branches
- **Could a reviewer in 6 months understand why this exists?** — naming, comments, commit message

Fix issues found. Do not just list them.

## 2. Pattern Conformance & Simplification

- **Does the new code follow existing patterns in the codebase?** — same layering, same naming, same test style, same config conventions. If it deviates, justify or align.
- **Is there duplication that should be extracted?** — copy-pasted logic, parallel if-branches, near-identical methods.
- **Is there over-engineering?** — unnecessary abstractions, interfaces with one impl, config flags nobody will toggle. Remove if simpler is sufficient.
- **Is the code the simplest correct version?** — refactor for clarity, not for cleverness.

Apply changes. Re-run format + tests.

## 3. Tests: Written, Seen Red, Then Green

For each test added or modified:

- **Did it fail (red) before the implementation?** — If not verified, temporarily break the production code, run the test, confirm it fails, then revert. A test that passes on broken code tests nothing.
- **Does it test the right thing?** — behavior, not implementation details. Not "method was called" but "outcome is correct".
- **Are edge cases covered?** — boundary values (off-by-one), null/empty input, error propagation, concurrent access where relevant.
- **Is the test readable?** — setup is minimal, assertions are specific, the name says what it verifies.

Run the full unit test suite. Read the `Tests run: N` line, not the report file.

## 4. Deployment Safety

- **Database migrations**: Flyway/Goose — forward-only? Reversible on rollback (or at least non-destructive)? `DEFAULT` values for NOT NULL columns on existing rows? Checksum-mismatch risk after branch switching?
- **Kafka**: new topics, consumer groups, or ACLs? If a consumer reads a topic, does the principal have Read+Describe? If producing, Write? Is retention appropriate for the data lifetime? Is the consumer group monitored (Burrow rule)?
- **Config**: new properties have sensible defaults so rolling deploys work with mixed versions? Feature flags documented?
- **Rolling deploy**: can old and new versions coexist briefly? Does the new column/event/flag break old pods that don't know about it?

Fix or document risks. Flag anything that needs manual deployment steps.
