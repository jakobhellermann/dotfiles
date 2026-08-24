- Nichts Zeitabhängiges aus dem Gedächtnis: Paketversionen, Sprach-Editions, Feature-/Flag-Namen, Spec- und Protokollrevisionen, Modell-IDs. Immer frisch holen — bevorzugt das Tooling entscheiden lassen (`cargo init`/`cargo add` statt handgeschriebener Cargo.toml, Registry-Abfrage statt getippter Version), sonst context7/Web; und wo es geht zur Laufzeit aushandeln statt hart zu kodieren.
- don't guess my intentions, ask for clarifications if necessary
- Eine tragende Annahme, die ich nicht aus Code/Daten/Quelle belegen kann, ist eine Frage an dich — nicht raten und darauf handeln (auch ein Hedge im Kleingedruckten rechtfertigt die Aktion nicht), sondern kurz nachfragen, besonders wenn du die Antwort weißt.
- Nie ein wörtliches Zitat oder das konkrete Verhalten einer fremden Quelle (README, Doku, Tool, API) aus dem Gedächtnis behaupten — erst die Quelle holen, dann zitieren/erklären. Eine Root-Cause-/Mechanismus-Erklärung ohne geprüfte Quelle als Vermutung labeln, nicht als Fakt präsentieren, und keine Folgeaktion (Edit, PR) darauf aufbauen, bevor sie belegt ist.
- **Grundsätzlich ist alles möglich, nur mit mehr oder weniger Aufwand.** Kein „geht nicht" aus einem
  Fehlschlag ableiten — eine Fehlermeldung ist eine Spur, keine Endstation (`SIGILL` heißt falscher
  Instruktionssatz, nicht kaputte Runtime). Erst die Ursache verstehen, dann den Aufwand benennen und
  mich entscheiden lassen.
- before removing or changing asserts, think about whether the actual code should change instead or ask me
- fail loud, don't silently swallow errors: surface or throw at the point of failure instead of catching-and-ignoring, defaulting away the problem, or degrading quietly. no empty/log-only catch blocks that swallow, no silent fallbacks that hide a real error, no "forgiving"/"ignore errors" flags chosen to avoid a crash. if a fallback is genuinely wanted, make it explicit and loud (or ask me) — don't reach for it by default
- never commit to vcs or do destructive actions without asking first
- don't write details of my local environment into public repos (e.g. workarounds for my global ~/.cargo/config.toml, personal paths, machine-specific tooling). fix such things in my local setup, not in shared/committed files.
- never read decrypted secrets into the conversation: don't `cat` rendered config files under /run, /etc/agenix, systemd `LoadCredential` paths, or anything an agenix/sops/systemd service decrypts at runtime. if you need to inspect such a file, redact first (e.g. `jq 'del(..|.token?,.password?)'`) or just describe the structure
- niemals pushen (git/jj push, PRs anlegen/updaten) ohne vorher explizit zu fragen — auch nicht als Folgeschritt eines vorher erlaubten Commits
- comments always in english, even if i talk in german
- be very sparse with code comments. don't paste the conversational rationale (the "why I'm doing this differently from before", references to what the test/helper used to do, ticket numbers, transformer rollouts) into source files. that context belongs in the chat or commit message. only comment when a reader of the code in 6 months without our chat history needs the hint to avoid a footgun — and then make it short. self-documenting code via good names is the first choice; comments are the last resort.
- keine backreference-kommentare ("X ruft das auf", "gelesen von Y", "läuft aus Z") — das liefert find-usages; rationale gehört an den konsumenten, nicht an das feld. beim verschieben/extrahieren von code jeden mitwandernden kommentar neu rechtfertigen wie neuen code statt ihn mitzukopieren.
- kommentare und doc-comments sind einzeilig; jede weitere zeile braucht eine eigene tatsache, die nicht aus name, signatur oder dem code darunter ablesbar ist. dieselbe erklärung nie an zwei stellen, und im doc einer funktion nie, was ihr aufrufer mit dem ergebnis macht.
- prefer asserting full matches, i.e. assertEqual instead of assering not empty or contains
- see a new test assertion fail without the fix before claiming it verifies anything — a green test alone only proves it runs, not that it catches the bug
- instead of piping tests directly to grep, tee them to a file and grep afterwards
- use double dollars to escape properties in spring kotlin: `@Value($$"${config.path.to.var}") private val foo: String`
- ripgrep (`rg`) is recursive by DEFAULT and `-r` is `--replace` (NOT grep's recursive). Never write `-rn`/`-rl`/`-rln` — the `-r` eats the following letters as a replacement string and silently rewrites every match in the output. Use `-n` alone for line numbers.
- prefer git WIP commits over stashes
- comments:
    - don't comment by default. comment when there is something non-obvious going on, that isn't self-explained by reading the code
    - if you see some tools not working well, don't immediately jump to alternative, attempt to fix them and make things better for everyone
    - don't leave comments about things _not_ happening, especially after removing a piece of code. they have to make sense in the context of someone reading the new code
    - all comments (doc and inline): one-liner by default. add more context only when absolutely necessary and not derivable from the surrounding code/signatures.
    - no back-references to consumers (don't describe who calls this or what they do with the result). describe the thing itself.


I'm using jj as my vcs, with full git compatibility.

Workflows:
- `jj` view commit graph, including changed files in the current commit @
- `jj diff [file]`
- `jj new abcd` start a new commit
- `jj desc -m "foo"` set the message
- `jj commit -m "foo" a b c` commit files a b c and create a new commit
- temporary checkouts (`jj new v1.2` to bisect for example) dont have to be named, that way they get auto cleaned)
- `jj run -r 'main..@' -- cargo c` runs a command across a whole range of revisions, each in an
  isolated working copy. This is THE tool for "does every commit build/test" — reach for it instead
  of manually looping. Add `--ignore-changes` to just check without rewriting commits (e.g. when the
  range is already pushed); omit it to amend each revision with the command's result.

_Never_ do jj describe without jj new. It inevitably leads to you accidentally making more changes
in this commit. Just do `jj commit [file] -m` to get a clean state on top.

Use single-line commit messages without co-authored-by by default, unless i ask for more context.

Commit message style: a SHORT imperative header (match the repo's existing style), then — when more context
helps — a blank line and a brief body of a few sentences. Do NOT cram everything into one long run-on header
line (no novels). Header says what; body says why / the key mechanism.

If a command line tool is helpful but not installed, ask me if I want to install it.

- niemals "🤖 Generated with Claude Code" o.ä. Signaturen in Commits, PR-Bodies oder sonstwo anführen
- prefer git switch over checkout
- dont use sdkman, use my global java/maven install
- when a command/package isn't installed, ask me if i should install it instead of finding alternatives
- if scanning a repo with gh is cumbersome, just clone it somewhere

# Kafka ACLs bei sipgate

Kafka-Topic-Berechtigungen für Services liegen in `~/dev/other/sipgate-deployment` unter `environments/<env>/vars/nautilus_kafka_user_create/main.yml` (dev und live getrennt). Symptom für fehlende ACL: `TopicAuthorizationException` / `TOPIC_AUTHORIZATION_FAILED` im Service-Log.

# Grafana / Loki bei sipgate

Bei "schau in die Logs für $service" direkt `mcp__grafana__query_loki_logs` aufrufen — kein Subagent.

- **Datasource UID `eb182461-aadf-429f-bf38-029837a7e9fe`** (loki-rrdns) — primär für alle Service-Logs.
- **Label `service_name`** matched den Repo-Namen, z.B. `pbxcore-read-model-writer`, `pbxcore-telco-service`, `trunking-telco-service`.
- **Label `environment`** = `dev` | `live`. Default `live`, bei Bedarf umschalten.
- **Label `level`** = `error` | `warning` | `info` | `debug`.
- Default-Zeitraum: **keinen** `startRfc3339`/`endRfc3339` angeben — Loki nimmt die letzte Stunde. (Explizite Zeiten erzeugen leicht UTC-Offset-Fehler → leere Ergebnisse → Fehlschluss "Service läuft nicht".)
- Default-Limit: 20–50, nicht mehr.
- Logs sind JSON. Für Felder: `... | json | line_format "{{.message}}"` oder filter auf `kafkaEventType`, `sessionId`, `logger_name`.
- **Zeitstempel in der MCP-Antwort sind UTC** (`_timestamp` endet auf `Z`, `timestamp` ist Unix-ns UTC). Die Grafana-UI zeigt mir lokale Zeit (CEST = UTC+2 im Sommer, CET = UTC+1 im Winter). D.h. UI-Zeit ist 1–2h voraus. Beim Einschränken eines Zeitraums entweder explizit mit Offset (`...+02:00`) oder gleich in UTC (`...Z`).

Typische Queries:
```logql
{service_name="pbxcore-read-model-writer", environment="live", level=~"error|warning"}
{service_name="pbxcore-telco-service", environment="live"} |= "AccountLocaleService"
{service_name="trunking-telco-service", environment="live"} | json | sessionId="sid_xyz"
```

Nicht "Service läuft nicht in dieser Env" sagen, nur weil eine Query 0 Ergebnisse hat — erst Label/Zeitraum/Datasource prüfen.

## Metriken (Prometheus/VictoriaMetrics) + persönliches Dashboard

- **Metrik-Queries** über `mcp__datapls__prometheus`, `action=grafana_query` (VictoriaMetrics via Grafana, **lange Retention** — reicht Monate zurück; für `action=query` braucht es ein `cluster`). Cluster-Label-Werte z.B. `k8s-daemon01-dev-hq01`, `k8s-daemon01-live-ix01`, `k8s-daemon01-live-ml01`.
- **Persönliches Spielwiesen-Dashboard**: „Spielwiese", **uid `bfwfl1l6c3egwb`** (Ordner „Jakob Hellermann" `efwfkwkd86ozkb`), https://grafana.sipgate.cloud/d/bfwfl1l6c3egwb/spielwiese. **Lesen** geht (`mcp__grafana__get_dashboard_by_uid`, `grafana_api_request` GET). Panel-Datasource: Prometheus/VictoriaMetrics **uid `o_5ugXKnz`** (lange Retention).
- **Dashboard-Write: direkter `curl`, NICHT übers MCP.** Das Grafana-MCP schreibt hier nicht (`mcp__grafana__update_dashboard` und `grafana_api_request POST /api/dashboards/db` → 404; k8s-API-PUT stiller No-op) — der Write-Pfad des MCP ist kaputt, unabhängig von Auth/Ordner. Ein direkter `curl POST /api/dashboards/db` mit SA-Bearer-Token **funktioniert** (auch in persönliche Ordner), Payload `{"dashboard": <model>, "overwrite": true, "folderUid": "<uid>"}`, HTTP-Status prüfen. Fertiges Setup dafür: `~/dev/me/grafana-spielwiese/` (`dashboard.json` + `import.sh` + direnv-`.env` mit `GRAFANA_TOKEN`).
- **Wann nutzen:** wenn eine Visualisierung mehr sagt als rohe Zahlen (Zeitverläufe, Vorher/Nachher, mehrere Serien überlagert) — Import-JSON bauen und uid/Link nennen, statt Zahlenkolonnen auszugeben.
- Nützliche Metriken fürs Memory-Sizing: `container_memory_working_set_bytes{container="<svc>", image!=""}` (echter RSS, = was Alert/OOM messen), `kube_pod_container_resource_limits{resource="memory"}` (Limit/OOM-Ceiling), `kube_pod_container_resource_requests{resource="memory"}` (Scheduling-Reservierung — **nicht** das Limit!). Namespace = `sg-<service>`; ein Namespace kann mehrere Workloads (Haupt- + Subservices) enthalten, dann per `workload`-Label (`namespace_workload_pod:kube_pod_owner:relabel`) oder Pod-Prefix trennen.



# Regeln

Mache niemals eine potenziell modifizierende/destruktive Änderung wie Datenbank Updates, Deletes, curl -X DELETE/PUT ohne vorher
explizit zu fragen.

# Arbeitsweise

Ich benutze jj vcs. Bitte immer arbeiten auf einem neuen unbennaanten commit, nicht einen bestehenden editieren.

- `jj log` (status, commits nach/vor mir)
- `jj new asdf` neuer commit auf commit mit change-id asdf / auschecken und temporäre änderungen machen bevor man committed
- `jj new -B @` `-A @` neuer commit vor/nach revset (@ = jetziger commmit)

Workflow:
- `jj new main` starte neuen branch
- `jj commit -m "feat: implement stuff" [file1 file2 file3]` create a new commit as parent from the changes
- `jj squash --use-destination-message [file1 file2] [--into xyz]` — `--use-destination-message` ist **immer** nötig, sonst öffnet jj einen Editor und blockiert (nur machen bei ungepushten änderungen per default)
- `jj new -A xyz --no-edit` mach einen neuen commit zwischen `xyz` and `xyz+` ohne ihn auszuchecken
- `jj diff -r main..bookmark-name`: branch diff
- `jj split` niemals ohne `-m` für message machen, sonst öffnet sich ein editor. Zum splitten kann mach auch gut einfach einen neuen commit machen, und dann selektiv `restore --from rev` machen.

Bitte _niemals_ jj describe verwenden um arbeit abzuschließen, nur `jj commit -m [file]..`. Mit describe bist du auf einem angefangen commits und die nächsten Änderungen gehen da rein.

- Vor jedem commit einmal `./mvnw spotless:apply -o`
- Vor jedem push einmal `./mvnw spotless:check -o`


Revsets:
- `xyz` commit, `xyz-` parent(s), `xyz+` child(ren), `jj help -k revsets` for more

Branches heißen BAUHAUS-xxxx-short-slug-english (jira nummer).

Niemals Co-Authored-By: Claude angeben.
Außerdem niemals jira referenzen wie BAUHAUS-2624, AC nummern, github link in code, doku oder commit messages hinterlassen.

# Services

Alle unsere services sind geklont unter ~/dev/bauhaus/projectname.
Andere services aus github.com/sipgate können in ~/dev/other geklont werden.


# Nützliche Commands

- Datenbankzugriff im Dev:
Manuell MySQL: `KERBEROS_USER=hellermann nautilusctl connect mysql -e dev -d db12 -s telco_endpoint_routing_service` (Passwort-Prompt, kein `-f` Flag verfügbar — Passwort aus 1Password via `op read "op://Employee/nautilusctl db/password"`)
Danach automatisch: `mysql -u hellermann -S /tmp/db12-dev-mysqld.sock telco_endpoint_routing_service -e "SELECT ...;"`

z.B. db05-replica01 für ser db

**SER-DB (`ser`) konkret** — Host `db05.dev.sipgate.net`, DB `ser`, User (ro) `pbxcore_telco_ro`. Zugriff:
```
# Terminal 1 (offen lassen, hält den Socket):
KERBEROS_USER=hellermann nautilusctl connect mysql -e dev -d db05-replica01 -s ser
# Passwort aus: op read "op://Employee/nautilusctl db/password"
# WICHTIG: der Kerberos-Prompt lässt sich NICHT pipen ("inappropriate ioctl for device")
#          → ich (Claude) kann den connect nicht selbst fahren; der User macht Terminal 1.
# Terminal 2 / hier:
mysql -u hellermann -S /tmp/db05-replica01-dev-mysqld.sock ser -e "SELECT ...;"
```
Nützliche Tabelle: `grp` (Gruppen-Mitgliedschaft) — `SELECT username, grp FROM grp WHERE mastersipid='<accountId>' AND grp='hide_displayname';`. `pbxcore`s Displayname-Toggle (`shouldHideDisplayName` → `isUsernameInGroup(mastersipid, toId, 'hide_displayname')`) liest genau diese Tabelle; `username` = die Ziel-Endpoint-ID (z.B. `1126226e1`), Channels stehen als UUID i.d.R. NICHT drin.

## Postgres (CNPG services)

Connect (hält Terminal offen, **forwarded 127.0.0.1:5432**, KEIN Socket wie MySQL):
```
nautilusctl connect postgres -e <dev|live> -r <service> -l <hq01|ix01> -f ~/.local/share/scripts/nautilusctl-password
```
- Location: **dev = hq01**, **live = ix01**.
- Läuft im Vordergrund und blockiert → in eigenem Terminal / Hintergrund starten und offen lassen.

**So arbeiten wir immer**: Ich (Claude) frage nur nach dem Tunnel — "führ mal `nautilusctl connect postgres -e live -r <service> -l ix01 -f ~/.local/share/scripts/nautilusctl-password` aus" — der User startet das in seinem Terminal, danach arbeite ich autonom weiter (Queries selbst absetzen, nicht für jede Query nachfragen). Gilt für mysql und postgres gleichermaßen.

**Immer einen fertigen Reason mitliefern.** nautilusctl fragt interaktiv in einer Textbox nach dem Zugriffsgrund (kein CLI-Flag). Also zu jedem Connect-Command eine eigene Zeile, kurz und ohne Zeilenumbruch, direkt kopierbar:
```
Grund: <was ich abfrage> (<Ticket>)
```
z.B. `Grund: Prüfe verwaiste Topic-Keys gegen phonenumber-Tabelle (BAUHAUS-2983)`. Keine Jira-Referenz in Code/Doku — in diesem Reason ist sie ausdrücklich erwünscht.

**Tunnel-Liveness prüfen, nicht annehmen.** Die Socket-Datei (`/tmp/<db>-<env>-mysqld.sock`) bleibt nach dem Beenden liegen und ist dann tot. Vor dem Schluss "kein Treffer" erst `pgrep -fl nautilusctl` — und niemals `|| echo "kein treffer"` an eine Query hängen, das maskiert `ERROR 2002` als Befund.

Passwort **einmal** cachen statt bei jeder Query einen 1Password-Prompt auszulösen:
```
~/.local/share/scripts/nautilusctl-password > /tmp/pgpassword && chmod 600 /tmp/pgpassword
# danach je Query:
PGPASSWORD=$(cat /tmp/pgpassword) psql "host=127.0.0.1 port=5432 user=hellermann dbname=app sslmode=require" -At -c "..."
```

Danach mit psql verbinden — Fallstricke, die jedes Mal Zeit kosten:
- **DB-Name ist `app`** (CNPG-Default), **nicht** der Schema-Name. Das **Schema** heißt wie der Service (z.B. `emergency_caller_id_service`) → Tabellen als `emergency_caller_id_service.<table>` ansprechen.
- **Passwort muss explizit** an psql (kein Auto-Auth über den Tunnel): `PGPASSWORD` aus `/tmp/pgpassword` (siehe oben).
- **`sslmode=require`** nötig.
```
PGPASSWORD=$(cat /tmp/pgpassword) \
  psql "host=127.0.0.1 port=5432 user=hellermann dbname=app sslmode=require" \
  -At -c "SELECT ... FROM <service_schema>.<table> ...;"
```
- DBs auflisten: `... dbname=postgres ... -c "SELECT datname FROM pg_database WHERE datistemplate=false;"` → `postgres`, `app`.

# Notes

- führe nicht standardmäßig alle integration tests aus, das dauert lange. erst unit tests, dann einzelne ITs und frag mich

# sipgate

Ich arbeite bei sipgate im team bauhaus. Die meisten docs zu sipgate findet man im tech-docs oder telco-docs repo. Im sipgate-deployment ist die meiste
infrastruktur definiert.

Per-repo infrastruktur wie alerting rules liegen in .sipgate/nautilus.yaml, oder .sipgate/subservice/nautilus.yaml.

Wir sind ein cloud-telefonanbieter. 

Wenn ein MCP gerade nicht verbunden ist, frage mich nach einem reconnect, statt nach workarounds zu suchen.

# Jira bei sipgate

- Base-URL ist https://sipgatede.atlassian.net — `sipgate.atlassian.net` ist tot, Links darauf gehen ins Nichts.
- Neu angelegte Issues landen im **Backlog**, nicht auf dem Board. Nach dem Create den Status auf `Tickets` setzen (`jira_set_status`), das ist die Default-Spalte für neue Stories/Bugs.
- Projekt BAUHAUS kennt die Typen Epic, Story, Sub-task, Bug, Research.

# Telefonie testing

Für autonome tests mit sip accounts, nimm beliebige passende geräte aus dem ai playground account: /Users/sipgatejj/dev/me/ai-playground-account/CLAUDE.md

# Codestyle

Kommentare sollten spärlich verwendet werden, und nur wenn sie dem Codeleser der zukunft einen klaren Mehrwert liefern.
Also gut:
- Begründung, die aus dem Kontext nicht klar wird
- Verweis auf validierte standards
Nicht gut:
- Beschreibung, wie eine Funktion von Konsumenten verwendet werden kann (!), auch nicht beim extrahieren

# Stille Fehlschläge vermeiden

Der teuerste Fehlermodus ist nicht der Absturz, sondern die Pipeline, die bei einem
Fehlschlag einen **plausibel aussehenden Wert** liefert — der dann als Befund gemeldet wird.
Deshalb verbindlich:

- **Kein `2>/dev/null` an datenliefernden Kommandos** (mysql, curl, psql, kcat, gh, …).
  Ein toter Tunnel liefert dann 0 Zeilen, und 0 Zeilen sehen aus wie ein Ergebnis.
- **HTTP-Status ist Teil der Daten.** Wird ein Body geparst, immer `-w '%{http_code}'` bzw.
  `--fail` prüfen: 401/429/5xx liefern oft einen leeren Body, und `curl -sS` schreibt dabei
  nichts nach stderr. Bei vielen Calls in Folge Rate Limits einplanen (`retry-after` + Backoff).
- **In Schleifen über viele Items nur validierte Ergebnisse persistieren** (erwartetes Feld
  vorhanden) und am Ende `ok=`/`fail=` ausgeben. Ein Fehlschlag darf keine Cache-Datei
  hinterlassen, sonst zementiert ihn der Rerun als „leer".
- **Plausibilitätsschwelle vor der Verwendung**: Wenn eine Abfrage Millionen liefern muss
  und 0 liefert, ist das ein Fehler und kein Befund → abbrechen, nicht weiterrechnen.
- **Leere Ergebnisse (SQL, Loki, grep, PromQL) sind erst ein Befund, wenn die Query selbst
  verifiziert ist.** Vorher eine Kontrollabfrage fahren, von der man weiß, dass sie treffen
  muss. Speziell bei Metriken/Labels: eine leere Antwort kann heißen, dass die Metrik oder
  der Label-Key gar nicht existiert (falscher Name), nicht dass das Attribut fehlt — erst
  Existenz prüfen (`count(<metrik>)`, `{__name__=~"..."}`), bevor man „gibt's nicht" sagt.
- **Zählungen zwei unabhängige Wege prüfen**, wenn die Zahl eine Entscheidung trägt.
  Und nicht auf Muster zählen, die auch in Kopf-/Statuszeilen vorkommen.
- **`|| echo "fallback"` hinter einem Kommando, das selbst schon ausgibt**, verkettet beide
  Ausgaben. Stattdessen `|| true` und danach auf leer prüfen.
- **Bei Skripten mit Schreibzugriff**: Dry-Run als Default, und den Default einmal wirklich
  testen. Ein `DRY_RUN=false` als Initialwert ist stumm gefährlich.
- **Zeitzonen**: Datei-mtimes und UI-Zeiten sind lokal, Unix-Timestamps und `date -u` sind
  UTC. Vor jedem Vergleich in eine Zone bringen, sonst erfindet man Erklärungen für eine
  Differenz von exakt 1–2 Stunden.
- **Jedes Glied einer Evidenzkette unmittelbar vor der Präsentation gegen die Quelle
  prüfen** — die Artefakt-Datei/DB zählt, die Erinnerung daran nicht. Hochrechnungen aus
  Einzelfällen („so wird das wohl generell gebaut sein") explizit als Vermutung labeln,
  und gecachte Identitäts-/Zuordnungsdaten (z.B. Helpdesk-Exports) mit Alter nennen.
- **Kein defensives Weitermachen im Code, den ich schreibe**: fehlende Voraussetzungen nicht
  per `continue`/`return` plus Warnung überspringen, sondern laut abbrechen (`throw`/`Assert`) —
  besser noch die Invariante in den Typ ziehen (`required`, nicht-nullable), damit der Fall gar
  nicht entstehen kann. Eine Warnung im Log ist kein Schutz, der Lauf bleibt grün.
- **Laut nur auf echten Fehlerpfaden.** „Fail loud" heißt Fehler und Handlungsbedarf sichtbar
  machen — nicht jeden geglückten, deterministischen Zwischenschritt (z.B. eine automatische
  Normalisierung) per Log/`echo` erzählen. Ein Log rechtfertigt sich durch Fehler, Warnung mit
  Handlungsbedarf oder Info, die der Leser wirklich braucht; sonst weglassen.

# Ringo (SIP-Softphone)

Ringo-SIP-Accounts sind in der nix-config konfiguriert: `~/nix-config/home/config/macos.nix` (Liste mit `name`/`username`/`password`/`prefix`/`number`; Namenskonvention z.B. `(aipg) Voiza 1` mit Prefix `jai-v1`). Das Ringo-Modul selbst liegt in `~/nix-config/home/modules/ringo/default.nix`.

# Rollout-Checkliste

Vor dem Merge eines Service-Deploys durchgehen:

- **Gibt es die ACLs?** Neue DB-Hosts, Kafka-Topics oder Zielsysteme brauchen einen eigenen
  Eintrag in `sipgate-deployment` (`nautilus_mysql_user_create`, `nautilus_kafka_user_create`).
  Ein Grant auf der Replica gilt nicht auf dem Master. Die Playbooks legen nur an
  (`state: present`), sie räumen nie auf — entfernte Einträge lassen den Grant stehen.
  **Grüner Ansible-Run beweist nichts**: das single-user-Playbook filtert über `db_host`/`db_user`,
  bei einem Tippfehler wird jeder Task übersprungen und der Run ist trotzdem grün. Immer auf
  `changed=N` im PLAY RECAP prüfen.
- **Gibt es die Egress-Policy?** Bei einem Host-Wechsel sind es zwei Stellen: die URL im Service
  und `egressNetworkPolicies` in `.sipgate/nautilus.yaml`.
  - **Kommen alte Pods mit der neuen Policy klar?** Die Policy greift, bevor der Rollout durch ist.
    Der alte Pod hat die alte URL im Speicher und läuft ins Timeout — `Communications link failure`
    aus `HikariPool$KeepaliveTask` im Übergangsfenster ist erwartbar. Vor dem Zurückrollen prüfen,
    aus welchem Pod die Fehler kommen: altes ReplicaSet = Lärm, neues = echter Defekt.
- **Keine JSON-Serialisierungsfehler.** Für neue Typen einen Serde-Test, der eine echte Payload
  round-trippt.

Nach dem Deploy nicht mit „Pod ist Ready" abschließen. Verbindungen zu fremden Systemen werden oft
erst beim ersten Trigger aufgebaut; ein sauberer Start beweist nur, dass der Prozess läuft. Den
ersten echten Durchlauf abwarten oder anstoßen und die Zahlen auf Plausibilität prüfen — ein Read,
der 0 statt N liefert, sieht in einem Diff-basierten Sync wie ein Löschauftrag aus.
