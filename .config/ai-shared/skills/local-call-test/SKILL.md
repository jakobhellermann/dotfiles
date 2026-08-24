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
| trunking-telco-service | `~/dev/bauhaus/trunking-telco-service/.claude/skills/local-call-test/SKILL.md` — eingehender Trunk-Call mit Forwarding-History, Trunk-Registrierung (sipconnect, UDP-only), Diversion-Verifikation |
| pbxcore-telco-service | `~/dev/bauhaus/pbxcore-telco-service/.claude/skills/local-call-test/SKILL.md` + `call-test-common.md` — webhook action-plans, stream WS, pbxcore-Read-Model-Sync |

Existiert für den Service kein Cookbook: das zuerst ansprechen und aufwärts bauen (Muster: eines der obigen), nicht ohne Doku improvisieren. Account-Grundlagen (Nummern, Extensions, Trunks, SIP-Creds, Footguns): `~/dev/me/ai-playground-account/AGENTS.md`.

## 3. Service-übergreifende Regeln (immer gültig)

- **Compose-Stack manuell hochfahren** vor jedem Run: `set -a; . ./.env; set +a && docker compose up -d`. Spring stoppt den Stack sonst beim Kontext-Shutdown (jeder Run zahlt vollen Start) und liest nach einem colima-Restart `Exited(255)`-Container als "already running".
- **Jeden Call mit `X-Client-Correlation-ID: test-<slug>-<uuid>` fahren** — der Wert wird `callSid` der Quell-Session und wandert als `X-TELCO-CAPTURE-ID` durch alle Folge-Sessions; damit ist die ganze Kette findbar ohne Loki-Grep.
- **baresip-MCP**: Account-Devices über TCP + `sip.dev.sipgate.de` (NAT-Pinhole für eingehende INVITEs); Trunks über UDP + `sipconnect.dev.sipgate.de` (TCP/TLS existiert für Trunking nicht) mit AOR-Domain `sipconnect.sipgate.de`; Callees brauchen `auto_answer_after_seconds`; baresip spielt lokales Audio (Ringback, Klingelton, empfangenes RTP) über coreaudio auf den System-Default-Output — per-App-Volume-Tools (Background Music) erfassen die bundle-losen CLI-Prozesse nicht (Slider-Liste kommt aus NSWorkspace runningApplications + Bundle-ID-Keys → kein Eintrag, auch nicht unter „More Apps"). Stummschalten: `BARESIP_AUDIO_PLAYER=none` als env des baresip-MCP in `~/.pi/agent/mcp.json` (greift erst nach Agent-Restart; Device-Namen als Wert müssen leerzeichenfrei sein, baresip kappt Config-Werte beim ersten Whitespace). Media-Verifikation weiterhin über HEPIC/Logs, nicht übers Ohr.
- **HEPIC nur über die `hepcli`-MCP-Tools** (`call_search`/`call_transaction`/`export_transaction`) — nie die Capture-SPA per curl reverse-engineeren. Responses >100k Zeichen landen als **einzeilige** Cache-Datei: `grep -o`/python, keine Zeilenzählung. HEPIC-Shares verfallen (~10 Tage Retention) — Original-Calls danach unrekonstruierbar.
- **Call-Inspektion**: `neopbx-devtools getCall(id=callSid)` — Response ist riesig, ins File und mit jq filtern. ITI-Event-Payloads (z.B. `forwardingHistory`) stehen in den Logzeilen → `searchsessions` im schmalen Zeitfenster.
- **Evidenz-Disziplin**: leere Treffer erst nach Positiv-Kontrolle als Befund werten (Control-Query im bekannten guten Fenster); wenn eine Sackgasse länger als 2 Versuche dauert → anderen Weg über Tools suchen oder nachfragen.

## 4. Während und nach dem Test

- Alle vom User gelieferten Infos und alle Missteps **sammeln** (Notizfile), danach die Cookbooks aktualisieren (service-seitig: Repo-Skill/AGENTS.md; account-seitig: `~/dev/me/ai-playground-account/AGENTS.md` + `inventory/` refresh). Das hält den Autonomie-Grad aktuell.
- Cleanup-Sektion des Service-Cookbooks vollständig abarbeiten: Routings reverten, baresip-AORs unregister (auch fehlgeschlagene Varianten), Webhook-Stubs/Tunnels killen, lokalen Service stoppen, Inventory auffrischen.
