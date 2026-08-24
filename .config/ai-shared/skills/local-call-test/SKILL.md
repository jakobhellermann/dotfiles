---
name: local-call-test
description: "Entrypoint für \"teste lokal\": ein echter Call wird durch den LOKAL laufenden telco-Service gegen dev-Infrastruktur geroutet (ohne Deploy). Ermittelt den betroffenen Service, delegiert an das service-spezifische Cookbook im Repo und hält das service-übergreifende Wissen (baresip, hepcli, Cleanup). Use when the user says \"teste lokal\" or wants to validate a telco-service patch end-to-end locally."
---

# Teste lokal (telco services)

Ziel: einen Patch/ein Verhalten end-to-end validieren, indem ein **echter dev-Call** durch den lokal laufenden Service geht. Kein Deploy, kein Mock-Server.

## 1. Betroffenen Service bestimmen

- Liegt das cwd in `~/dev/bauhaus/<service>` → das ist der Service.
- Sonst aus Kontext ableiten (aktives Ticket/Story nennt den Service, z.B. Jira-Component).
- Mehr als ein Kandidat oder keiner erkennbar → **nachfragen**, nicht raten.

## 2. Service-spezifisches Cookbook lesen (das Detailwissen)

Je nach Service liegt das Rezept im Repo — **immer das Cookbook lesen, bevor Tools benutzt werden**:

| Service | Cookbook |
|---|---|
| trunking-telco-service | kein Cookbook auf `main` (nur `localToDev`-Profil in der AGENTS.md) — erst ansprechen |
| pbxcore-telco-service | `AGENTS.md` → „Local to Dev" + „Rerouting dev calls to your local instance" (Slots, Read-Models, Ports). Ausführlicheres Cookbook nur auf Branch `wip/local-development-skills` (`.claude/skills/local-call-test/`) |
| hi-iti-simple-call-service | `AGENTS.md` → „Local call test against dev" — braucht zusätzlich einen lokalen pbxcore |

Existiert für den Service kein Cookbook: das zuerst ansprechen und aufwärts bauen (Muster: eines der obigen), nicht ohne Doku improvisieren. Account-Grundlagen (Nummern, Extensions, Trunks, SIP-Creds, Footguns): `~/dev/me/ai-playground-account/AGENTS.md`.

## 3. Service-übergreifende Regeln (immer gültig)

- **`HI_ITI_SIMPLE_CALL_SERVICE_LOCAL_<n>` als Routing-Ziel heißt: ein LOKALER pbxcore auf Slot n** (ITI-Topic `iti.public.team.pbxcorelocal<n>.events`). Der deployte dev-pbxcore konsumiert das nicht — eine `external-api-config` für den LOCAL-Slot auf dem deployten pbxcore wird nie gelesen (verifiziert 2026-10-19: Alice-Session wählt, für Bob entsteht keine Session). Ein lokaler Hi:ITI-Service braucht also immer einen lokalen pbxcore davor; der ruft den Service direkt über `localhost`, kein Tunnel nötig.
- **Was auf den LOCAL-Slot zeigen muss**: Nummer (number-routing, eingehend) **und** Endpunkt (endpoint-routing `incoming`) des Ziels — interne Anrufe wählen das Ziel als Endpunkt, die Nummer allein greift dort nicht. Bei internen Anrufen zusätzlich der **Anrufer-Endpunkt `outgoing`**: der pbxcore der Anrufer-Seite legt die Internal-Call-Korrelation in SEINER DB ab; liegen beide Seiten auf verschiedenen pbxcores, verwirft die Zielseite mit „No internal call correlation found".

- **Compose-Stack manuell hochfahren** vor jedem Run: `set -a; . ./.env; set +a && docker compose up -d`. Spring stoppt den Stack sonst beim Kontext-Shutdown (jeder Run zahlt vollen Start) und liest nach einem colima-Restart `Exited(255)`-Container als "already running".
- **Jeden Call mit `X-Client-Correlation-ID: test-<slug>-<uuid>` fahren** — der Wert wird `callSid` der Quell-Session und wandert als `X-TELCO-CAPTURE-ID` durch alle Folge-Sessions; damit ist die ganze Kette findbar ohne Loki-Grep.
- **baresip-MCP**: Account-Devices über TCP + `sip.dev.sipgate.de` (NAT-Pinhole für eingehende INVITEs); Trunks über UDP + `sipconnect.dev.sipgate.de` (TCP/TLS existiert für Trunking nicht) mit AOR-Domain `sipconnect.sipgate.de`; Callees brauchen `auto_answer_after_seconds`; baresip spielt lokales Audio (Ringback, Klingelton, empfangenes RTP) über coreaudio auf den System-Default-Output — per-App-Volume-Tools (Background Music) erfassen die bundle-losen CLI-Prozesse nicht (Slider-Liste kommt aus NSWorkspace runningApplications + Bundle-ID-Keys → kein Eintrag, auch nicht unter „More Apps"). Stummschalten: `BARESIP_AUDIO_PLAYER=none` als env des baresip-MCP in `~/.pi/agent/mcp.json` (greift erst nach Agent-Restart; Device-Namen als Wert müssen leerzeichenfrei sein, baresip kappt Config-Werte beim ersten Whitespace). Media-Verifikation weiterhin über HEPIC/Logs, nicht übers Ohr.
- **HEPIC nur über die `hepcli`-MCP-Tools** (`call_search`/`call_transaction`/`export_transaction`) — nie die Capture-SPA per curl reverse-engineeren. Responses >100k Zeichen landen als **einzeilige** Cache-Datei: `grep -o`/python, keine Zeilenzählung. HEPIC-Shares verfallen (~10 Tage Retention) — Original-Calls danach unrekonstruierbar.
- **Call-Inspektion**: `neopbx-devtools getCall(id=callSid)` — Response ist riesig, ins File und mit jq filtern. ITI-Event-Payloads (z.B. `forwardingHistory`) stehen in den Logzeilen → `searchsessions` im schmalen Zeitfenster.
- **Evidenz-Disziplin**: leere Treffer erst nach Positiv-Kontrolle als Befund werten (Control-Query im bekannten guten Fenster); wenn eine Sackgasse länger als 2 Versuche dauert → anderen Weg über Tools suchen oder nachfragen.

## 4. Geschriebene Szenarien (neo-telco-tests) gegen den lokalen Stack

Szenarien laufen **nativ** per Maven/Failsafe — kein Docker-Image, kein calltest-runner-Container:
`baresip` kommt vom PATH, die Account-Topologien (inkl. SIP-Passwörter) liegen als JSON im Repo.

- **Lokaler Test-Branch**: `calltest-copy` → `calltest-copy-local` (jj-Chain im
  neo-telco-tests-Klon). `calltest-copy` zeigt `Dev.kt` auf die hellermann-Copy-Topologien
  (`~/.config/sipgateaccounts/hellermann-dev-{primary,extern}.json`), `calltest-copy-local`
  enthält `LocalServiceRouting` (`routeVoizasToService` = Nummer+Endpoint incoming,
  `routeCallersToService` = Endpoint outgoing → `HI_ITI_SIMPLE_CALL_SERVICE_LOCAL_2`) und die
  lokalen Erwartungen der 3288-Tests. Neue lokale Szenario-Anpassungen als Commit auf dieser
  Chain, nie auf main.
- **Ausführen**: `make dev.<Klassenname>` bzw. `make 'dev.<paket>.**'` (ruft mvn failsafe auf;
  Reports unter `calltest-suites/target/failsafe-reports/`, im Failure hängt der SIP-Trace an der
  Assertion). Echte dev-Calls — nur mit freigegebenem Account, nie parallel zum getriggerten
  Deployment-Suite-Lauf derselben Devices.
- **Api-Transfer-Szenarien** brauchen den hi-iti-call-test-service lokal: jar mit
  `--spring.profiles.active=local`, per `.env` (Muster `.env.example`) zeigen `PBXCORE_SERVICE_URL`
  aufs lokale pbxcore und `SERVICE_DB_HOST`/`LOCAL_DB_HOST_PORT` auf die eigene MySQL (compose,
  Default 3308 kollidiert mit hi-iti-ser-db → 3309). Im lokalen neo-telco-tests-Commit
  `devCallTestServiceTransfers` auf `http://localhost:8081` umstellen.
- **Ports**: hi-iti-simple-call-service liest `LOCAL_SIMPLE_CALL_SERVICE_PORT` aus seiner `.env`
  (8080 ist frei für pbxcore, dessen default der call-test-service-Default-URL entspricht).
- **Read-Models des lokalen pbxcore**: Der read-model-writer braucht frische, eindeutige Consumer-Group-IDs — sonst fehlen lokal historische Routing-Events (interne Transfers wählen ins Leere). Die localToDev-Defaults enden auf `-local` und teilen sich alle Entwickler (deren Offsets überspringen alte Events); mit dem deployed Writer kollidieren sie nicht (der hängt `-<cluster-location>` an). Persönliche Namen stehen in
  `pbxcore-read-model-writer/src/main/resources/application-localToDev-gitignored-custom.properties`
  (Suffix `-local-hellermann`) und werden **beim Build ins Jar gepackt** — nach Änderung neu
  bauen. DB-Wipe ⇒ neue Namen ⇒ earliest ⇒ Full-Replay.

## 5. Während und nach dem Test

- Alle vom User gelieferten Infos und alle Missteps **sammeln** (Notizfile), danach die Cookbooks aktualisieren (service-seitig: Repo-Skill/AGENTS.md; account-seitig: `~/dev/me/ai-playground-account/AGENTS.md` + `inventory/` refresh). Das hält den Autonomie-Grad aktuell.
- Cleanup-Sektion des Service-Cookbooks vollständig abarbeiten: Routings reverten, baresip-AORs unregister (auch fehlgeschlagene Varianten), Webhook-Stubs/Tunnels killen, lokalen Service stoppen, Inventory auffrischen.
