- use context7 mcp server to look up-to-date info, docs and versions
- don't guess my intentions, ask for clarifications if necessary
- before removing or changing asserts, think about whether the actual code should change instead or ask me
- never commit to vcs or do destructive actions without asking first
- niemals pushen (git/jj push, PRs anlegen/updaten) ohne vorher explizit zu fragen — auch nicht als Folgeschritt eines vorher erlaubten Commits
- comments always in english, even if i talk in german
- be very sparse with code comments. don't paste the conversational rationale (the "why I'm doing this differently from before", references to what the test/helper used to do, ticket numbers, transformer rollouts) into source files. that context belongs in the chat or commit message. only comment when a reader of the code in 6 months without our chat history needs the hint to avoid a footgun — and then make it short. self-documenting code via good names is the first choice; comments are the last resort.
- prefer asserting full matches, i.e. assertEqual instead of assering not empty or contains
- instead of piping tests directly to grep, tee them to a file and grep afterwards
- use double dollars to escape properties in spring kotlin: `@Value($$"${config.path.to.var}") private val foo: String`
- ripgrep (`rg`) is recursive by DEFAULT and `-r` is `--replace` (NOT grep's recursive). Never write `-rn`/`-rl`/`-rln` — the `-r` eats the following letters as a replacement string and silently rewrites every match in the output. Use `-n` alone for line numbers.
- prefer git WIP commits over stashes
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
Außerdem niemals jira referenzen wie BAUHAUS-2624, AC nummern, github link in code und doku hinterlassen.

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
- **Plausibilitätsschwelle vor der Verwendung**: Wenn eine Abfrage Millionen liefern muss
  und 0 liefert, ist das ein Fehler und kein Befund → abbrechen, nicht weiterrechnen.
- **Leere Ergebnisse (SQL, Loki, grep) sind erst ein Befund, wenn die Query selbst
  verifiziert ist.** Vorher eine Kontrollabfrage fahren, von der man weiß, dass sie treffen
  muss.
- **Zählungen zwei unabhängige Wege prüfen**, wenn die Zahl eine Entscheidung trägt.
  Und nicht auf Muster zählen, die auch in Kopf-/Statuszeilen vorkommen.
- **`|| echo "fallback"` hinter einem Kommando, das selbst schon ausgibt**, verkettet beide
  Ausgaben. Stattdessen `|| true` und danach auf leer prüfen.
- **Bei Skripten mit Schreibzugriff**: Dry-Run als Default, und den Default einmal wirklich
  testen. Ein `DRY_RUN=false` als Initialwert ist stumm gefährlich.
- **Zeitzonen**: Datei-mtimes und UI-Zeiten sind lokal, Unix-Timestamps und `date -u` sind
  UTC. Vor jedem Vergleich in eine Zone bringen, sonst erfindet man Erklärungen für eine
  Differenz von exakt 1–2 Stunden.
