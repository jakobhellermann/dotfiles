- don't guess my intentions, ask for clarifications if necessary
- never commit to vcs or do destructive actions without asking first
- comments always in english, even if i talk in german
- comments only when absolutely necessary: one-liner by default, only if not obvious from context. No backreferences ("same as above"), no prose.
- Keine Referenzen auf Interna anderer Projekte/Services in Code-Kommentaren (Klassennamen,
  Konstanten-Pfade aus fremden Repos) — Kommentare beschreiben den eigenen Code bzw. den
  API-Contract der Schnittstelle, nicht die Implementierung der Gegenseite.
- instead of piping long-running processes directly to grep, tee them to a file and grep afterwards
- If a command line tool is helpful but not installed, ask me if I want to install it.
- never assert a fact without validating it first with all tools you have at hand.
I'd rather take 30 minutes to understand why something fails, than continue with a guess immediately.
- Error diagnoses are assertions too: for tool errors (404, denied, timeout) validate the
  cause first via a counter-test (e.g. try an alternative tool with different
  credentials) instead of presenting a plausible-sounding cause as the explanation.
- Never conclude "tool X can't do it" from `--help` output alone: config file options
  (e.g. `[package.metadata.*]`) often don't appear as CLI flags. Check the schema/docs/crate
  source (in `~/.cargo/registry/src/`) before building a manual workaround.
- RTFM, always when possible: before designing against, building with, or debugging an
  unfamiliar tool/API/framework, read its primary docs first (README, `docs/`, official site
  — the full document, not search snippets). Search highlights, other projects' source, and
  experiments are only for questions the docs leave open.

# sipgate infrastructure knowledge

- netzquadrat (NQ) = sipgate. NQ gateways, LB-NQ, netzquadrat.de domain — all sipgate-owned infrastructure, no external carrier.
- Die Bauhaus-Standards (Coding, Logging, Testing, Alerting) liegen im `hi-iti-docs`-Repo unter
  `~/dev/bauhaus/hi-iti-docs/pages/bauhaus-intern/` (z.B. `bauhaus-standard.md`) — es gibt kein
  separates "bauhaus-docs"-Repo auf GitHub. Telco-/Classic-Telco-Doku: `~/dev/other/telco-docs`.

# telco legacy infrastructure

- nmsd (Numbering Management Daemon) manages porting data in the `numberingManagement`
  DB. Replica hosts: `repl-nmsd-01.service.sipgate.net`,
  `repl-nmsd-02.service.sipgate.net` (user `safranro`, read-only). These hosts
  are **not** reachable via `nautilusctl connect mysql -d db05-replica01` —
  they are dedicated legacy hosts. Configuration in
  `sipgate-deployment/environments/<env>/group_vars/sip_gateway_safran/main.yml`.
- The Safran gateway (`sip-gateway-safran`, Yate) resolves the TNB (carrier network
  operator) of a phone number via `num2tnb()` in `safran-yateconfig/bin/route.php`.
  The function calls the stored procedure `getTnb()` on an nmsd replica.
  Lookup cascade in `nmsd/lib/NMSD/NMSD_PDA.pm` `GetTnb4Phone`:
  1. `aknn_routing` (direct lookup, then longest-prefix match)
  2. `aknn_data_XX` (XX = first 2 digits without 49; porting data, `active='Y'`)
  3. `aknn_RNB` (number block assignment, from 6 chars)
  4. default `D001` (unknown)
  D146 = sipgate. A stale TNB entry here leads to calls being routed internally by mistake.
- safran-yateconfig and nmsd repos are cloned under `~/dev/other/`.

# sipgate neo (NeoPBX)

- For call issues start with `neopbx-devtools searchsessions` (free text: device id
  like `3821665e3`, error text, number) in a NARROW time window (timed out on 3h,
  fine on 1h) — the log excerpts often already contain the reject reason.
- Then `neopbx-devtools getcall(sessionId)` for the event journal + `errorLogs`
  (pbxcore level). `retel session_get(sessionId)` is the layer below: raw ITI
  events/commands on the kafka transport level, no per-event logs — only for when
  the pbxcore view isn't enough.
- HEPIC call_id == retel tracingId on the sipgate.de leg (verified: the device's
  INVITE carries it as SIP Call-ID), so `call_search(call_id=<tracingId>)` finds
  the leg. Calls rejected inside pbxcore (REJECT_CLIENT → 603) never reach the
  proxy → no SIP traffic → HEPIC empty: switch to searchsessions instead of
  permuting filters.
- AOR format: `sip:<masterSipId>e<ext>@...` — the user part before `e<ext>` is the
  masterSipId for helpdesk lookup.
- Per-endpoint outgoing CLI lives in `helpdesk_lookup(query=numbers)` → `outgoing[]`.
  A CLI not in the account's number block (`phoneNumberId: null`, owned by no
  customer) makes pbxcore reject outgoing calls with 603.

# database access

## MySQL (legacy, DB05 replica)

- Connect (user must keep the terminal open, Kerberos prompt is not pipable):
  `KERBEROS_USER=hellermann nautilusctl connect mysql -e dev -d db05-replica01 -s ser`
  Password: `op read "op://Employee/nautilusctl db/password"`
- Afterwards work autonomously: `mysql -u hellermann -S /tmp/db05-replica01-dev-mysqld.sock ser -e "..."`
- Check socket liveness before concluding "no match": `pgrep -fl nautilusctl`
- The `numberingManagement` DB (nmsd porting data) runs on its own hosts
  `repl-nmsd-01/02.service.sipgate.net`, **not** reachable via `nautilusctl -d
  db05-replica01`.
- Dev databases do not necessarily contain the same data as live. Searching dev
  DBs to make claims about live customers, numbers, or routing yields no valid
  results. Helpdesk search and neopbx-devtools deliver live data — prefer those.

## Postgres (CNPG services)

- Connect: `nautilusctl connect postgres -e <dev|live> -r <service> -l <hq01|ix01> -f ~/.local/share/scripts/nautilusctl-password`
  dev = hq01, live = ix01. Runs in the foreground → own terminal.
- The DB name is `app` (CNPG default), **not** the schema name. Schema = service name.
- Queries: `PGPASSWORD=$(cat /tmp/pgpassword) psql "host=127.0.0.1 port=5432 user=hellermann dbname=app sslmode=require" -At -c "..."`
- Cache the password: `~/.local/share/scripts/nautilusctl-password > /tmp/pgpassword && chmod 600 /tmp/pgpassword`

## working with DB tunnels

- I only ask for the tunnel connect, afterwards I work autonomously (run the
  queries myself). Include a ready-made reason with every connect command
  (nautilusctl interactively asks for the access reason). Format:
  `Grund: <what I'm looking up> (<ticket>)` — e.g.
  `Grund: Checking orphaned topic keys against the phonenumber table (BAUHAUS-2983)`

# tool usage

- When a task matches the description of an available skill, read that SKILL.md
  before reaching for tools directly — it encodes the known-fast path and saves
  detours.
- `helpdesk_search` is a full-text search over customer attributes: name, email,
  phone number, masterSipId, company, city, zip code. It matches exactly when the
  number/id is assigned to an active sipgate customer; for ported-away or no longer
  assigned numbers it only returns fuzzy partial matches on neighbors (same number
  block, same city, etc.). Use the search to get the masterSipId from imprecise
  input (names, emails, companies). To check whether a concrete number is still
  routed by us, use neopbx-devtools routing queries or `helpdesk_lookup` (with a
  known masterSipId) instead.
- If a relevant repo is not cloned locally, clone it into `~/dev/other/`
  (`jj git clone git@github.com:sipgate/<repo>.git ~/dev/other/<repo>`), then analyze it.
  External (non-sipgate) projects always go to `~/dev/contrib`.
  Always clone with `jj git clone`, never plain `git clone` (existing plain clones can be
  fixed afterwards with `jj git init --colocate`). Don't guess, don't skip.
- If a needed access is missing (DB, infrastructure, repo), ask the user instead
  of continuing without it. Also ask about alternatives if the known path didn't work.
- **Keine persönlichen Pfade in geteilte/committbare Dokumente**: `~/dev/...`, `~/.local/...`,
  `$HOME` etc. sind meine privaten Klon-/Konventionspfade — sie gehören nie in AGENTS.md,
  README, Wikis, Tickets oder andere geteilte Artefakte. Dort nur Repo-Namen (`sipgate/<repo>`)
  und zugehörige Dateipfade im Repo bzw. offizielle URLs angeben; persönliche Pfade nur in
  SYSTEM.md/SKILL.md (privat) verwenden.
- **Keine blind verlinkten Inhalte**: Wenn ich nicht verifizieren kann, was auf einem
  Dashboard/ einer Seite steht (z.B. Grafana ohne API-Zugriff), sage ich das explizit
  und frage nach Zugang oder der richtigen URL/Panel-ID — statt einen Kandidaten
  nach Titel zu verlinken und mit Disclaimer weiterzuziehen. Erst fragen, dann
  benennen: keine Platzhalter-Namen (z.B. "panel-103") im Dok, bevor der Inhalt
  bestätigt ist.
- **Skill-Frontmatter valide halten**: Beim Schreiben/Ändern einer SKILL.md keine `: `-Sequenz in unquoted YAML-Scalaren (bricht das Skill-Loading mit "Nested mappings are not allowed") — Werte sicherheitshalber in doppelte Anführungszeichen setzen. Frontmatter-Validierung: `sed -n '/^---$/,/^---$/p' <file> | yq eval '.'`
- **GitHub-PRs nie über die `datapls_github_pr_write` MCP-Tools (sipclaw-Bot) erstellen** —
  der PR-Autor ist dann sipclaw statt mir. Stattdessen `gh pr create` über die CLI nutzen
  (Branch muss vorher gepusht sein). Gilt analog für Issues/Kommentare, die unter meinem
  Namen erscheinen sollen.
- **ilspycmd nie als Einzeltyp-ad-hoc-Decompile** — immer Full-Assembly dekompilieren:
  `ilspycmd <assembly.dll> -o ~/.personal/hkss/game/decomp/<name>-<version> -p`, danach aus
  den generierten Dateien lesen. Existierende Verzeichnisse dort zuerst ansehen (Naming-
  Konvention, ggf. schon dekompiliert).

## Lokale IT-Infrastruktur (docker compose)

- **IT-Compose-Stack immer manuell hochfahren**: Vor IT-Runs selbst
  `set -a; . ./.env; set +a && docker compose up -d` ausführen, nicht Spring überlassen —
  Spring stoppt den Stack beim Kontext-Shutdown, sodass jeder weitere Maven-Run den vollen
  Container-Start zahlt; nach einem colima-Restart bleiben Container außerdem als Exited(255)
  liegen, die Spring als "already running" fehlinterpretiert.

## Grafana / PromQL / Loki (datapls_prometheus)

- LogQL (alles mit Stream-Selektor `{...}`) → `action: "loki_query"`; PromQL → `action: "grafana_query"` (VictoriaMetrics). LogQL über grafana_query endet in 422.
- Prometheus-Label hier: `pod`/`job`/`namespace`/`instance` — `pod_name` existiert nur in Loki. Unbekannte Label-Sets mit `topk(1, <metrik>)` inspizieren statt raten; Tell für falsches Label: `by(<label>)` liefert genau eine Gruppe mit leerem Label.
- Leere Loki-Treffer in alten Zeitfenstern sind kein Befund, solange nicht per Kontrollquery (`{service="..."}`, limit 1) bewiesen ist, dass dort überhaupt Logs liegen — Retention nur ~10 Tage. Suchtext aus dem echten Exception-Text (Code/Log), nicht aus der Ticket-Paraphrase; im Zweifel breiter suchen.
- Kontrollqueries müssen die Annahmen der Ursprungs-Query unabhängig prüfen (Label-Wert, Regex-Anchoring, Zeitfenster liegt in der Vergangenheit, JSON-Feldname) — teilen sie dieselbe Annahme, bestätigen sie zirkulär das eigene Raten statt es zu entlarven.
- Ein Nicht-Finden nie mit einer plausiblen Erklärung als Fakt begründen („der Service loggt nicht, weil VM-Service“) — Label-/Feldnamen werden nicht erraten, sondern validiert (Label-Discovery, Shipper-Config, User fragen) oder klar als Vermutung gekennzeichnet.
- Liefert eine Loki-Query exakt `limit` Zeilen, ist sie trunkiert — Gesamtzahlen aus Metrik-Countern holen, nicht aus Logzeilen zählen.
- Getaggte Micrometer-Counter sind lazy (Serie entsteht beim ersten Increment, stirbt mit Pod/JVM, Reset bei JVM-Restart): `increase()/rate()` über lange Fenster unterzählt. Stattdessen betroffene Pods mit `last_over_time(<counter>[lookback])` auflisten (liefert auch tote Pods mit Endwert) und die Endwerte summieren.
- Kurzlebige Serien (<1 h) sieht eine Range-Query mit grobem Step nicht (5-min-Lookback je Eval-Punkt) — solche via Instant-Query mit Lookback (`last_over_time`/`max_over_time`) finden und das Fenster schrittweise eingrenzen.
- Keine spontanen `and on()`-Joins zweier Metriken — getrennt abfragen und erst dann kombinieren. CNPG-Metriken nur mit `state`-Label lesen (`cnpg_backends_total` active vs idle) und den Primary pro CNPG-Cluster über `cnpg_pg_replication_in_recovery == 0` plus `cluster`-Label identifizieren (pro Namespace laufen mehrere Cluster: ix01/ml01/dev).
- Vor Batch-Loops in mcpScript: einen Probe-Call absetzen und die Roh-Form prüfen (datapls liefert `r.data.content[0].text`, JSON-in-Text), plus ein bekannt-positives Kontrollfenster in den Batch legen — sonst fallen Parse-Bugs als stille "0" auf.

# HEPIC (SIP-Captures)

- Datenzugriff über die `hepcli`-MCP-Tools (`call_search`, `call_transaction`, `export_transaction`) mit `env=dev|live` — HEPIC-Share-Links verfallen (~10 Tage Retention); für dauerhafte Referenzen Deep-Links + Call-ID dokumentieren.
- Deep-Link in die Capture-UI: `https://<host>/search/result#/60_call_h20/<fromEpochMs>/<toEpochMs>/sip.callid=<sipCallId>` — Zeitfenster in Epoch-ms (z.B. Tagesgrenzen). Hosts: live = `telco-capture.sipgate.net`, dev = `telco-capture.dev.sipgate.net` (`telco-capture.live.sipgate.net` existiert nicht).
- `sip.callid` ist die SIP Call-ID **des Legs** (aus `hepcli call_search` → `callid`), nicht die trunking/ITI-sessionId — bei Trunking z.B. die Call-ID des GW-Anlagen-Legs; die Verknüpfung Session↔Leg läuft über `X-TELCO-CAPTURE-ID` bzw. die Correlation-ID.

# VCS

I'm using jj as my vcs, with full git compatibility.

- Run even pure inspection (status, log, branches, diff) through jj
  (`jj status`, `jj log`, `jj diff`), not git — in jj repos detached HEAD is
  normal and git output ("Not currently on any branch") is misleading.

Workflows:
- `jj` view commit graph, including changed files in the current commit @
- `jj diff [file]`
- `jj new [rev]` start a new commit on revision
- `jj desc -m "foo"` set the message
- `jj squash -f rev -t rev -u` (-u is use destination message, otherwise you open an editor)
- `jj commit -m "foo" a b c` commit files a b c and create a new commit
- temporary checkouts (`jj new v1.2` to bisect for example) dont have to be named, that way they get auto cleaned)

_Never_ do jj describe without jj new. It inevitably leads to you accidentally making more changes
in this commit. Just do `jj commit [file] -m` to get a clean state on top.
- Nie auf einem beschriebenen Commit stehenbleiben — sofort `jj new`, sonst landen weitere Änderungen unbemerkt darin.

- **Pushen macht der User, nicht ich** — committen/bookmarken ja, aber nie selbst `jj git push` ausführen, auch nicht "logisch zugehörig" zum Auftrag (z.B. PR-Update nach Fix). Nur auf explizite Aufforderung pushen.
- **Before every `jj git push`: look at `jj log` once** — check that the bookmark is
  on the tip (last commit), not on a middle commit. A bookmark on a middle commit
  pushes only that commit + ancestors, not the descendants. Run `jj log` **with
  graph lines**, not `--no-graph`: the question is an ancestry question, and without
  the graph sibling branches interleave so the linear reading order suggests
  parent-child relationships that do not exist.
- **While a PR is under review, do not push every single fix** — accumulate changes
  locally (working copy or local commits) and push only when the reviewer asks or
  a batch is complete. Each mid-review push re-triggers CI and buries the reviewer's
  place in the diff.
- **Fallout-Fixes eines fremden Commits nicht in meinen eigenen Task-Commit mischen** —
  wenn meine Änderung kompiliert nur, weil ich Fallout eines anderen Commits fixe
  (oder umgekehrt), vorher klären, in welchen Commit der Fix gehört (z.B. dorthin
  squashen), statt ihn stillschweigend in meinen eigenen Commit zu packen.
Use single-line commit messages without co-authored-by by default, unless i ask for more context.

Commit message style: a SHORT imperative header (match the repo's existing style), then — when more context
helps — a blank line and a brief body of a few sentences. Do NOT cram everything into one long run-on header
line (no novels). Header says what; body says why / the key mechanism.



# working approach

- **Lokal nur relevante Tests ausführen — den Rest macht CI**: bei einer Änderung gezielt
  die direkt betroffenen Test-Klassen (plus nah angrenzende Pfade, die dieselbe Komponente
  berühren) laufen lassen; kein lokaler Full-Run (`verify` über die ganze Suite) — der läuft
  ohnehin in CI und kostet lokal >30 min ohne zusätzlichen Befund.

- Questions the compiler can answer (compilability, types, signatures) should not
  be played through in your head — run `cargo check`/`cargo clippy`. Mental
  type-checking is wasted time and error-prone.
- A green build also settles API/target-framework availability — once something
  compiles, don't manually verify (docs/TFM lists) that the APIs it uses exist
  (e.g. netstandard coverage).

Don't just start implementing. Try to understand bugs with all the tools at
your hand. Then we discuss the solution and keep debugging. Only once we have
a clear implementation plan do we implement.

Afterwards we validate the fix, and only then commit.
