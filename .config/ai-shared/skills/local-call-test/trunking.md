---
name: local-call-test
description: End-to-End-Test des lokal laufenden trunking-telco-service gegen dev — eingehender Call mit Weiterleitung an einen baresip-Trunk-Endpoint, Verifikation der Forwarding-History (connecttrunk-Body) und des gerenderten Diversion-Headers. Use when asked to "teste lokal" (trunking), einen Call-Flow gegen den lokalen Service reproduzieren oder einen Trunking-Patch end-to-end validieren.
---

Eingehenden Anruf **mit Forwarding-History** durch den lokal laufenden `trunking-telco-service` (gegen dev) schicken und prüfen, dass die Weiterleitungsinformation (a) im `connecttrunk`-Command ankommt und (b) von neo als `Diversion`-Header in den INVITE zur Anlage gerendert wird.

Kontext-Referenzen: Account-Cookbook ist `~/dev/me/ai-playground-account/AGENTS.md` (Playground-Account 1127298 DE / 1127337 UK, Trunks, SIP-Hosts, Footguns). Das Muster für lokale Services ist `~/dev/bauhaus/pbxcore-telco-service/.claude/skills/` (dort läuft ein analoges Setup für pbxcore).

## Flow-Überblick

```
baresip (UK-Account, externer Anrufer)
  → dev SIP-Edge → retel: Call auf Kanal-Nummer
  → Kanal-Weiterleitung (memberlos → sofort) auf Trunk-Nummer
  → retel: ClientNumberCalling mit forwardingHistory  ← Glied 1
  → iti.public.team.trunkinglocal.events
  → LOKALER trunking-telco-service: connecttrunk      ← unser Patch (1:1)
  → dev ITI/retel: INVITE zur Trunk-Anlage mit
     Diversion-Header                                 ← Glied 2 (neo rendert)
```

## 1. Lokalen Compose-Stack hochfahren (immer manuell!)

Spring stoppt den Stack beim Kontext-Shutdown selbst — und nach einem colima-Restart bleiben Container als `Exited(255)` liegen, die Spring als "already running" fehlinterpretiert. Vor jedem IT/Local-Run:

```bash
set -a; . ./.env; set +a && docker compose up -d
```

## 2. Trunk-Nummer auf den Trunk routen (Playground-Account)

Nummern + Trunk-Creds stehen im Playground-Account (`./scripts/sg` aus `~/dev/me/ai-playground-account`, `SG_ACCOUNT=1127298`):

```bash
./scripts/sg GET v2/numbers | jq '.items[] | select(.endpointId == "")'   # freie Nummer suchen
./scripts/sg GET v3/trunks        # credentialsUsername/Password/Registry/Proxy
./scripts/sg PUT v2/numbers/<numberId> - <<< '{"endpointId":"t0"}'
```

## 3. Routing auf die lokale Instanz überschreiben

Die lokale Instanz konsumiert das **dev**-Routing-Topic direkt in ihre lokale Postgres (`PhoneNumberRoutingConsumer`, kein read-model-writer nötig — anders als bei pbxcore). Ackzeptierte TargetTypes: `ITI_SIPGATE_TRUNKING`, `_LOCAL`, `_LOCAL_1`, `_LOCAL_2` (→ Topics `trunking[local|local1|local2].events`).

```bash
# targetType für die lokale Topic-Variante (default config = trunkinglocal.events):
curl -X PUT 'https://phone-number-routing-service.k8s-daemon01.dev.hq01.sipgate.net/v1/routing/incoming/<e164OhnePlus>' \
  -H 'Content-Type: application/json' \
  -d '{"accountId":"1127298","targetType":"ITI_SIPGATE_TRUNKING_LOCAL","targetId":"1127298t0"}'
```

Verify: `neopbx-devtools getNumberRouting(<e164>)` → `targetType: ITI_SIPGATE_TRUNKING_LOCAL, matchingType: EXACT`. Lokal nach Start prüfen: `SELECT * FROM trunking_telco_service.number_incoming_routing_read_model WHERE number LIKE '<e164>%'` (docker exec auf `trunking-telco-service-postgres-db-1`, User `trunking_telco`, Pass in `docker-compose.yml`).

## 4. baresip als Trunk-Endpoint registrieren

**Trunking-SIP-Hosts (abweichend von Accounts!):** Registrar dev wie live `sipconnect.sipgate.de`, Dev-Outboundproxy `sipconnect.dev.sipgate.de`, **nur UDP — TCP/TLS gibt es für Trunking (noch) nicht** (daher auch kein SRTP). Die AOR-Domain muss `sipconnect.sipgate.de` sein: mit `@sipgate.de` antwortet der sipconnect-Proxy `404 unknown domain`, der General-Proxy `sip.dev.sipgate.de` kennt Trunk-Creds nicht (`401`).

```python
register(aor="sip:1127298t0@sipconnect.sipgate.de",
         username="1127298t0", password="<aus v3/trunks>",
         transport="udp", outbound_proxy="sip:sipconnect.dev.sipgate.de",
         auto_answer_after_seconds=2, regint=30)
```

`regint=30` hält das UDP-NAT-Pinhole frisch; Auto-Answer, weil der Trunk der Callee ist. **UDP-NAT-Fußnote:** der INVITE kann trotzdem hängen (VPN) — das schadet der Header-Verifikation nicht, denn die läuft über HEPIC, nicht über baresip.

## 5. Lokalen Service starten

```bash
./mvnw package -DskipTests
set -a; . ./.env; set +a
nohup java -jar target/trunking-telco-service.jar --spring.profiles.active=localToDev > /tmp/trunking-local.log 2>&1 & disown
until curl -sf localhost:8080/health > /dev/null; do sleep 2; done && echo READY
```

Verbindet gegen dev-Kafka (`iti.public.team.trunkinglocal.events`), dev-ser-db, billingd-dev und ITI-REST-dev. Alternativen Topic-Sets (`trunkinglocal1/2`) stehen kommentiert in `application-localToDev.properties` — nur eine lokale Instanz pro Set, mit dem Team koordinieren.

## 6. Weiterleitungs-Szenario bauen (KRITISCHER PUNKT)

**Ein `Diversion`-Header am baresip-Dial überlebt den Ingress NICHT** — das Event kommt mit `forwardingHistory: []` an (verifiziert). Die Weiterleitung muss die Plattform selbst erzeugen. Rezept: memberlosen Playground-Kanal per Channel-Forwarding auf die Trunk-Nummer leiten (Forwarding-Rezepte + Fallstricke: siehe Playground-AGENTS.md „Channel-Weiterleitungen"):

```bash
CH=<channelId>; TS=$(./scripts/sg GET "v3/routing/$CH/time-sets" | jq -r '.items[0].id')
./scripts/sg GET "v3/routing/$CH/time-sets/$TS/forwardings" | jq .   # Original sichern!
./scripts/sg PUT "v3/routing/$CH/time-sets/$TS/forwardings" - <<'EOF'
{"forwardings":{
  "UNREACHABLE":[],"OFFLINE":[],
  "BUSY":[{"delay":0,"destination":{"target":"+49<TrunkNr>","type":"PHONENUMBER"}}]}}
EOF
```

Memberloser Kanal → sofortiger BUSY-Forward → neuer Call auf die Trunk-Nummer mit `forwardingHistory`.

## 7. Call fahren

Externen Anrufer via **UK-Account** simulieren (anderes Konto ⇒ `from.accountId=null`; Device-callerId default `anonymous` — der Call ist dann komplett anonym, was die `ANONYMOUS`-History-Einträge erzeugt):

```python
dial(account="sip:1127337e1@sipgate.co.uk",
     uri="sip:+49<KanalNr>@sipgate.co.uk",
     headers={"X-Client-Correlation-ID": "test-trunk-<slug>"})
```

Die Correlation-ID wird `callSid` der Quell-Session **und** wandert als `X-TELCO-CAPTURE-ID` bis ins terminating INVITE — damit findet man alle Glieder der Kette.

## 8. Verifizieren

**a) Unser Patch (connecttrunk-Body)** — lokales Log:

```bash
grep "Connecting Trunk Request" /tmp/trunking-local.log | tail -2
# erwartet: forwardingHistory=[ForwardingEntry(number=…, reason=…, anonymous=…)]
# ITI-Antwort: "response status: '200'"
```

**b) Event-Zusammensetzung durch retel** (optional): `neopbx-devtools searchsessions` mit der Correlation-ID/Nummer im schmalen Fenster — die Logzeilen enthalten den vollen `ClientNumberCalling`-Payload.

**c) Header-Rendering durch neo (Glied 2)** — HEPIC via **`hepcli`-MCP-Tools, nicht per curl an die Capture-SPA**:

```
hepcli call_search(env=dev, callee=startswith:<TrunkNr>, from/to=Call-Fenster)
hepcli call_transaction(call_id=<terminating call-id>, env=dev, redact=false)
```

`call_search` zeigt bereits `CustomString->Key/Value = Diversion`. Aus dem Transaction-Output (wird als Datei gecacht, mit grep/python auswerten — keine Zeilen-Semantik!) den raw INVITE extrahieren:

```python
# doppelte Escapes auflösen: \\r\\n → \r\n, \\\" → "
# erwartet im INVITE zur Anlage:
#   Diversion: <sip:ANONYMOUS@sipgate.de>;reason=no-answer;privacy=full
#   Privacy: id
```

Rendering-Regeln (verifiziert): Nummer **1:1** (`ANONYMOUS` bleibt `ANONYMOUS`), Reason lowercased mit Bindestrich (`NO_ANSWER` → `no-answer`), `privacy=full` aus dem anonymous-Flag. Es wird **Diversion** gerendert, kein `History-Info` (auch bei `Supported: histinfo`) — entspricht neo-Team-Aussage (BAUHAUS-3089-Thread).

## 9. Cleanup (vollständig!)

1. **Routing löschen** — `PUT /v2/numbers` mit leerem `endpointId` wird mit 400 abgelehnt; stattdessen:
   `curl -X DELETE https://phone-number-routing-service…/v1/routing/incoming/<e164>` → verify `getNumberRouting` = `null`
2. **Channel-Forwarding reverten** (gesicherten Original-Body per PUT zurück)
3. **Alle baresip-Registrierungen unregistern** (auch fehlgeschlagene AOR-Varianten spawnen Instanzen!)
4. **Lokalen Service stoppen** (`kill <pid>`), Stack darf laufen
5. **Inventory auffrischen**: `./scripts/sg GET v2/numbers | jq . > inventory/1127298/v2_numbers.json` (+ ggf. AGENTS.md-Stand im Playground-Repo anpassen)

## Fallstricke (Leerkosten-Doku)

- `10000@sipconnect.…` klingelt ohne Ton: während RINGING fließt keine Media ohne Early Media — kein Fehler.
- Hepcli-Responses (`call_transaction` >100k Zeichen) landen in einer Cache-Datei **ohne Newlines** — `grep -c` zählt Zeilen nicht Treffer; mit `grep -o`/python arbeiten.
- HEPIC-Share-Links verfallen (Share geleert + Retention) — Original-Calls sind nach ~10 Tagen unrekonstruierbar; nur `hepcli call_search` gegen Live-Daten hilft solange.
- `sip:100…@sipgate.de` direkt zu wählen geht nicht ("is not a valid number") — immer E.164-Nummern wählen.
- Spring docker-compose lifecycle: siehe Schritt 1 — manuell starten, sonst zahlen alle Runs den vollen Container-Start.
