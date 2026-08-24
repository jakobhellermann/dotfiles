---
name: story-start
description: Bereitet eine Jira-Story für die Implementierung vor — liest Ticket + Kontext, inspiziert die betroffenen Services im Code (read-only), und klärt offene Fragen mit dem User, bis der Implementierungsansatz steht. Implementiert NICHT. Use beim Start einer neuen Story ("/story-start BAUHAUS-1234" oder mit Jira-URL).
argument-hint: <JIRA-KEY | Jira-URL>
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(git grep:*), Bash(git branch:*), Bash(git remote:*), Bash(ls:*), Bash(find:*), Bash(rg:*), Bash(wc:*), Bash(cat:*), Agent, Task, AskUserQuestion, WebFetch, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getJiraIssueRemoteIssueLinks, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources
effort: high
---

# Story Start: Story verstehen, Services ansehen, Ansatz klären

```
   Ticket ─▶ Kontext ─▶ Code (read-only) ─▶ Fragen klären ─▶ Ansatz steht
                                                     │
                                                     ▼
                                            (KEINE Implementierung)
```

Ziel dieses Skills: eine Story so weit durchdringen, dass ein **abgestimmter
Implementierungsansatz** existiert — Ticket + Diskussion gelesen, die betroffenen
Services im echten Code angesehen, und alle offenen Fragen mit mir geklärt.

**Harte Grenze: nicht implementieren.** Keine Edits, kein neuer Code, keine
Migrations, keine Commits. Nur lesen, verstehen, fragen. Am Ende steht ein Plan,
den ich freigebe — die Umsetzung ist ein separater, späterer Schritt.

Sprache: Deutsch (sipgate-Team), außer ich wünsche ausdrücklich Englisch.

---

## Phase 0 — Jira-Key auflösen

Argument: `$ARGUMENTS`

- Ist es schon ein Key (`BAUHAUS-\d+`)? Direkt nehmen.
- Ist es eine Jira-URL? Key extrahieren — meist aus `selectedIssue=BAUHAUS-XXXX`
  oder dem Pfad. **Base-URL ist `https://sipgatede.atlassian.net`** (das nackte
  `sipgate.atlassian.net` ist tot).
- Kein Argument? Aus dem aktuellen Branch ableiten (`feat/BAUHAUS-1234-…`).
  Sonst mich fragen — nicht raten.

cloudId für alle Atlassian-Calls: `d9f1e0b4-bbce-4bc5-8ca1-73ba50a4d868`.
Bei `cloudId not found` → `getAccessibleAtlassianResources` und korrekte UUID nehmen.

---

## Phase 1 — Story + Jira-Kontext laden

`getJiraIssue` mit vollem Feldsatz (inkl. `comment`, `description`, `issuelinks`,
`parent`, `subtasks`, `labels`, `components`), `responseContentFormat: markdown`.

Lies und halte fest:

- **Titel, Beschreibung, Akzeptanzkriterien** — die ACs sind der Vertrag.
- **Kommentare** — hier steckt oft der eigentliche Kontext: Entscheidungen,
  verworfene Ansätze, Rückfragen. Nicht überspringen.
- **Epic / Parent** und **Sub-tasks** — nachladen, wenn sie den Scope prägen.
- **Verlinkte Issues** (`issuelinks`, ggf. `getJiraIssueRemoteIssueLinks`) —
  blockiert von / relates to / Duplikate; kurz anlesen.
- **Status, Assignee, Labels, Components** — Component zeigt oft direkt den Service.

Wenn der Kontext groß ist: pro Achse (Beschreibung/ACs, Kommentare, verlinkte
Issues) an einen `general-purpose`-Agent delegieren und knappe Zusammenfassungen
zurückholen, statt alles roh in den Kontext zu ziehen.

**Nach Phase 1**: mir eine kurze Story-Zusammenfassung geben (Was soll erreicht
werden, welche ACs, was ist schon geklärt) — damit wir dasselbe Verständnis haben,
bevor wir in den Code gehen.

---

## Phase 2 — Betroffene Services ansehen (read-only)

Zuerst ableiten, **welche Services** betroffen sind — aus ACs, Component,
Kommentaren, genannten Topic-/Tabellen-/Klassennamen.

- Bauhaus-Services liegen unter `~/dev/bauhaus/<name>`, andere sipgate-Repos
  unter `~/dev/other/<name>`.
- Wenn ein relevantes Repo nicht lokal geklont ist, nach `~/dev/other/` klonen
  (`git clone git@github.com:sipgate/<repo>.git ~/dev/other/<repo>`), dann analysieren.
  Nicht raten, nicht auslassen.

Dann den Code **lesen, nicht ändern**. Für breite Suchen `Explore`- oder
`general-purpose`-Agenten fan-out einsetzen; sie sollen **Fundstellen mit
`file:line`** zurückgeben, keine ganzen Files. Pro Service klären:

- **Wo dockt die Änderung an?** Einstiegspunkte, Handler, Services, die betroffene
  Domäne. Konkrete Klassen/Methoden mit Pfad.
- **Welche bestehenden Muster** gibt es für Ähnliches? (Layering, Namensgebung,
  Test-Stil, Config-Konventionen — wir wollen uns einreihen, nicht neu erfinden.)
- **Datenflüsse**: Kafka-Topics (produce/consume), DB-Tabellen/Schemas, HTTP-APIs,
  Avro-Schemas. Was müsste sich wo mitändern?
- **Tests**: welche Test-Klassen decken das Umfeld ab, wo käme ein neuer Test hin.
- **Nachbarschaft**: was hängt dran, was bricht potenziell (Abwärtskompatibilität,
  Rolling-Deploy, Consumer die ein geändertes Event lesen).

Leere Suchtreffer sind erst ein Befund, wenn die Suche verifiziert ist — im
Zweifel eine Kontrollsuche fahren, von der du weißt, dass sie treffen muss, bevor
du "gibt's nicht" sagst.

**Nach Phase 2**: mir einen faktischen Lagebericht geben — betroffene Services,
Andock-Stellen (`file:line`), Datenflüsse, und die **offenen Punkte**, die den
Ansatz noch blockieren.

---

## Phase 3 — Offene Fragen klären (iterativ)

Jetzt die Lücken schließen. Typische Achsen:

- **Scope-Grenzen**: was gehört rein, was ist explizit außen vor / Follow-up.
- **Grenzfälle & Fehlerpfade**: was passiert bei fehlenden Daten, Race, Teil-Fehlschlag.
- **Datenmodell/Migration**: neue Spalten/Topics/Schemas? Abwärtskompatibel?
- **Alternativen**: wenn es mehrere sinnvolle Wege gibt, die Optionen mit Trade-offs
  gegenüberstellen und mich entscheiden lassen — nicht selbst festlegen.

Für konkrete Entscheidungen `AskUserQuestion` nutzen (Optionen mit kurzer
Trade-off-Beschreibung, Empfehlung zuerst). Freie Rückfragen, wo eine Auswahlliste
nicht passt. **Iterieren**, bis keine ansatz-blockierende Frage mehr offen ist —
lieber eine Runde mehr fragen als auf einer Annahme aufbauen.

---

## Phase 4 — Ansatz festhalten (nicht umsetzen)

Wenn alles geklärt ist, den abgestimmten Ansatz kurz zusammenfassen:

- **Vorgehen**: die Schritte in Reihenfolge, je Service.
- **Betroffene Stellen**: Files/Klassen (`file:line`), neue vs. geänderte.
- **Daten/Deploy**: Migrations, Topics/ACLs, Config, Rolling-Deploy-Verträglichkeit.
- **Test-Strategie**: welche Tests, welche ACs sie abdecken.
- **Bewusst außen vor / Risiken**: offene Annahmen, Follow-ups.

Dann anbieten, mit der Implementierung zu starten (eigener Schritt) — oder auf mein
Signal warten. **Hier endet der Skill; nicht ungefragt weiterbauen.**

---

## Anti-Muster (nicht tun)

- **Nicht implementieren.** Keine Edits/Writes/Commits/Migrations in diesem Skill.
- **Betroffene Services nicht raten** — im Code verifizieren; fehlende Repos melden.
- **Keine Annahme still stehen lassen** — offene Frage = an mich, nicht wegdefiniert.
- **Kein "geht nicht" aus einer Fehlermeldung** — Ursache verstehen, Aufwand benennen,
  mich entscheiden lassen.
- **Keine Jira-/AC-Referenzen** planen, die später im Code/Doku landen sollen.

## Failure-Modes

- **MCP Atlassian nicht verbunden** → mich um Reconnect bitten, nicht per WebFetch
  am Login vorbei improvisieren.
- **Repo nicht geklont** → Klon anbieten, nicht die Analyse auslassen.
- **Story unklar/dünn** → genau das ist Phase 3; nachfragen statt annehmen.

## Beispiel-Aufruf

```
/story-start BAUHAUS-3008
/story-start https://sipgatede.atlassian.net/…&selectedIssue=BAUHAUS-3008
```
