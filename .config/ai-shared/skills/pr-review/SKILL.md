---
name: pr-review
description: "Checkt einen PR aus (Branch suchen, Jira-Story ansehen, PR-Body/Kommentare lesen, Diff ansehen) und reviewet ihn. Read-only — findet Bugs, Konventionsverstösse und Deploy-Risiken, ändert nichts. Nimmt GitHub-Link, PR-Nummer oder Branch-Namen. Review-Output bewusst knapp: nur non-triviale Funde, Details auf Nachfrage."
argument-hint: <PR-URL | PR-Nummer | Branchname>
---

# PR Review: auschecken, verstehen, reviewen

Ablauf: Input auflösen → PR-Metadaten + Jira → `jj git fetch && jj new <branch>@origin` → Diff → Review. **Read-only**, Ergebnis kurz halten.

## Phase 0 — Input auflösen

Argument: `$ARGUMENTS`

- **PR-URL** (`github.com/<owner>/<repo>/pull/<n>`) → owner, repo, Nummer extrahieren.
- **Nur Nummer** → Repo = aktuelles Working-Directory-Repo; wenn cwd kein passendes Repo ist, nachfragen statt raten.
- **Branch-Name** → direkt nehmen. Existiert dazu ein PR (`gh pr list --head <branch> --repo <owner>/<repo> --json number,url`)? Dann dessen Metadaten mitnehmen; sonst ohne PR reviewen, Diff-Basis ist `main@origin`.

Repo ≠ cwd → unter `~/dev/bauhaus/<repo>` bzw. `~/dev/other/<repo>` suchen; fehlt es, mit `jj git clone git@github.com:sipgate/<repo>.git ~/dev/other/<repo>` klonen (bei Unsicherheit, ob Bauhaus, fragen).

## Phase 1 — PR-Metadaten + Jira lesen

```bash
gh pr view <n> --repo <owner>/<repo> --json number,title,body,author,state,baseRefName,headRefName,headRepositoryOwner,url
gh pr view <n> --repo <owner>/<repo> --comments   # Body + Review-Threads
gh pr checks <n> --repo <owner>/<repo>            # CI-Status
```

- Jira-Key aus Branch (`feat/BAUHAUS-1234-…`), Titel oder Body ableiten; Story via `datapls_jira_issues get_issue` laden — Beschreibung + **ACs** + Kommentare überfliegen. Kein Key → notieren, weitermachen.
- `state` beachten: closed/merged nur hinweisen, Review trotzdem liefern.
- Head `owner:branch` (Fork-PR) → Fork erst als Remote (`jj git remote add fork <url> && jj git fetch fork`); alles Weitere gleich, nur die Rev-Adresse ändert sich.

## Phase 2 — Checkout

```bash
jj st                     # offene Änderungen? `jj new` behält sie als Commit — im Zweifel vorher klären
jj git fetch
jj new <branch>@origin
jj log -r <branch>@origin --no-pager   # plausibilisieren: Tip + Author sichtbar
```

Danach im ausgecheckten Stand arbeiten (Dateien direkt lesen statt aus dem Diff raten).

## Phase 3 — Diff + Story zusammenführen

- Autoritativer Diff: `gh pr diff <n> --repo <owner>/<repo>` (Merge-Basis, nicht `jj diff` gegen evtl. zurückgebliebenes `main@origin`).
- Geänderte Dateien im Checkout vollständig lesen, wo der Diff allein nicht reicht (Kontext, Caller, Tests). Riesiger Diff → pro Datei agenten-unterstützt lesen statt halbgare Funde liefern.
- Erste Brille: erfüllt der Diff die ACs? Scope creep? Fehlende Teile?

## Phase 4 — Review

Checkliste, Reihenfolge nach Impact:

1. **Story-Bezug**: ACs erfüllt? Unnötiger Zusatz-Scope?
2. **Korrektheit**: Fehlerpfade, Null/leere Collections, Races/Partial-Failure, verschluckte Exceptions, Defaults, die Bugs maskieren.
3. **Tests**: decken Verhalten ab (nicht Implementierungsdetails)? Offensichtliche Lücken?
4. **Repo-Konventionen**: AGENTS.md des Repos beachten — im pbxcore-telco-service z. B.: neue DomainEvents in `DomainEventEvolutionTest` registrieren, MockK statt Mockito, `@FailOnLog` an ITs, Avro-Builder statt Positions-Konstruktoren, keine Legacy-`EventJournal`-Helper, ktfmt/spotless.
5. **Deploy-Sicherheit**: Flyway (forward-only, NOT NULL mit Default?), Kafka (Topic/ACL/Retention, Burrow-Rule), Config-Defaults für Rolling Deploy, alte+neue Pods koexistenzfähig?
6. **CI**: rot? Dann PR-Kommentar `verify-pr-failure-<module>` gegenprüfen — Flaky (nur in älterem Kommentar) vs. deterministisch (auch im neuesten).

## Output-Format (wichtig)

Knapp. Nur non-triviales.

- Funde gruppieren: **Blocker** / **Sollte gefixt** / **Nit**, je Item `file:line` + 1–2 Sätze.
- Unauffälliges nicht aufzählen — max. ein Satz Gesamturteil („Rest unauffällig, deckt die ACs ab").
- Keine Diff-Zusammenfassung, keine Schritt-Chronik, nichts wiederholen, was im PR-Body steht.
- Details/Codevorschläge erst auf Nachfrage ausrollen; am Ende anbieten: „Zu welchem Punkt willst du mehr?"

## Grenzen

- **Read-only**: keine Edits, kein spotless:apply, keine Commits, kein Push.
- Findings zuerst mir zeigen; als GitHub-Review posten nur auf ausdrückliches Verlangen (`gh pr review` / `gh pr comment` unter meinem Namen, nie als Bot).

## Beispiel-Aufrufe

```
/pr-review https://github.com/sipgate/pbxcore-telco-service/pull/2290
/pr-review 2290
/pr-review feat/BAUHAUS-3008-name-of-branch
```
