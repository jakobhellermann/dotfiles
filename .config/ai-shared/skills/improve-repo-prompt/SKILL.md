---
description: Run this when I tell you that you made an avoidable mistake, to update the current project's AGENTS.md with a preventive, project-specific rule. Variant of improve-system-prompt for repo-level guidance.
---

# Improve AGENTS.md (repo prompt)

When invoked, the user is telling you that you made an avoidable mistake. Your job:

## 1. Understand the mistake
Ask the user what the mistake was if it's not obvious from context. Identify the concrete, generalizable principle that would have prevented it.

## 2. Decide the right target: AGENTS.md vs. SYSTEM.md
- Would the rule only apply to this repo (build commands, test selection, repo-specific workflows, tool gotchas of this codebase)? → AGENTS.md (this skill).
- Would it prevent the same mistake in any other project? → use `improve-system-prompt` instead (SYSTEM.md). Projekt-übergreifende Regeln gehören nie ins AGENTS.md.
- Bei gemischten Fällen: die generalisierte Regel nach SYSTEM.md, den projekt-spezifischen Anteil (Konkretisierung am hiesigen Tooling) nach AGENTS.md.

## 3. Write the rule into the repo's AGENTS.md
Add a concise, actionable rule to the AGENTS.md (or CLAUDE.md — whichever the repo uses) of the current working directory.
- Put it in the most fitting existing section (e.g. build/test commands, gotchas, conventions), or create a new one matching the doc's structure.
- Project-specific is fine and expected here: field names, plugin names, command flags, paths of THIS repo may (and should) appear — unlike SYSTEM.md rules, no abstraction needed. Test: die Regel muss auch ohne den Vorfall-Kontext für einen Neuankömmling im Repo verständlich und umsetzbar sein.
- Don't restate rules that already exist; extend or refine them instead.
- Write in the language of the section you're editing (match the existing doc).
- Geteiltes/committbares Dokument: keine persönlichen Pfade (`~/dev/...`, `$HOME`), keine Referenzen auf Interna anderer Projekte/Services — nur Reponamen und Pfade im eigenen Repo.
- Keine transienten Zustände ("aktuell blockiert", "bis X geht") — Regel beschreibt dauerhafte Semantik; Vorbehalte gehören in die Commit-Message.

## 4. Commit
Commit the AGENTS.md change like any other work in this repo (explicit file path, repo's commit-message style). Pushing remains the user's job.
