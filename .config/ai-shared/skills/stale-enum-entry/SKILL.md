---
name: stale-enum-entry
description: 'Analysiert portierte/exportierte Rufnummern, die aus dem sipgate-Netz nicht erreichbar sind oder intern noch auf alte Anschlüsse zeigen (Verdacht: stale ENUM-Eintrag in ser.pstn2sip auf DB05). Sammelt Routing-Zustand, ENUM-DNS-Antwort, pstn2sip-Rows, Account-Stand und Call-Flow — nur Analyse, der Mensch entscheidet und löscht. Use when a ported-away number is unreachable from the sipgate net, still rings on sipgate devices, or a pstn2sip/ENUM cleanup is suspected.'
---

# Portierte Nummer (Export) nicht aus sipgate-Netz erreichbar — ENUM-Diagnose

**Nur Analyse & Datensammlung.** Entscheidung und Löschung macht der Mensch
(bauhaus-Team, Live-Primär-DB; Vorläufe BAUHAUS-2731/-2644/-2631). Dieser Skill
liefert den entscheidungsreifen Befund und stoppt dort.

## Symptom
Nummer vom Kunden wegportiert, aber Anrufe (intern oder eingehend über Carrier-Routen)
landen weiterhin auf altem sipgate-Anschluss oder schlagen fehl. Klassische
Verdachtsursache: veralteter ENUM-Eintrag in `ser.pstn2sip` (DB05) — der enumdns
beantwortet NAPTR-Requests mit der Regex, mit der Kamailio die SIP-Request-URI
rewritet, und hält den Call dadurch im sipgate-Netz. **Ebenso möglich: Portierungsdaten
routen noch zu D146 (sipgate), obwohl die Nummer längst abgebaut ist** (s. Schritt 5).

## Ablauf

### 1. Nummer normalisieren
E.164 ohne führendes `+` (z.B. `06002 1699` → `4960021699`). Mehrere Nummern in einem Rutsch.

### 2. Zwei Lookups (kein Tunnel, keine Auth)
1. ENUM-DNS: `enum-lookup 4960021699 496002992414 ...` — Script in `~/.local/bin`
   (default live, `-d` für dev-Zone; akzeptiert `+49…`/`0049…`/`0…`/`49…`;
   Exit 0 = NAPTR-Antwort, 1 = keine). Fallback ohne Script:
   `dig @dns-resolver.netzquadrat.net $(rev <<< 4960021699).enum.live.sipgate.net NAPTR +short`
2. Routing: MCP `datapls_neopbx_devtools_live_getnumberrouting` (dev-Variante ohne `_live`)

### 3. Entscheidungsmatrix
| Routing | NAPTR | Befund | Weiter |
|---|---|---|---|
| null | ja | **Stale ENUM-Eintrag**: aktive pstn2sip-Row trotz Export | Schritt 4, dann Befund |
| null | nein | Keine aktive Row — ENUM scheidet als Ursache aus | Schritt 5 (HEPIC), Verdacht Portierungsdaten/nmsd |
| da | ja | Leak: ITI-Nummer, deren Unterdrückung bei TIRP-Fehler undicht wird (transient) | erneut abfragen; reproduzierbar → enumdns/TIRP-Problem |
| da | nein | Normalzustand einer ITI-Nummer | nichts auffällig |

Warum die Matrix stimmt: enumdns (`sgenum20d`) fragt **vor** der SQL-Query den TIRP
(`http://…/legacy/routing/<Nummer>`); nur `isItiTarget=true` unterdrückt die Antwort —
unabhängig von der Row. TIRP-Fehler (Timeout/500) unterdrücken **nicht** → die Row
leakt dann als NAPTR-Antwort. DNS-Stille beweist das Fehlen einer aktiven Row also nur
bei Routing=null; bei vorhandenem Routing sagt sie nichts über die Row aus.

### 4. Rows + Kontext (DB05-Live-Replica, read-only)
Tunnel — User-Terminal (Kerberos-Prompt nicht pipable, Grund wird interaktiv abgefragt):

    KERBEROS_USER=hellermann nautilusctl connect mysql -e live -d db05-replica01 -s ser
    # Grund: pstn2sip-Rows für portierte Nummer prüfen (ENUM-Stale-Diagnose) (<Ticket>)

Danach autonom (Socket `/tmp/db05-replica01-live-mysqld.sock`, dev analog `…-dev-…`):

    mysql -u hellermann -S /tmp/db05-replica01-live-mysqld.sock ser -e "
      SELECT phone, sipid, mastersipid, register_domain, force_billing, expires, temporary
      FROM pstn2sip WHERE phone IN ('4960021699', '496002992414')"

- `phone` = E.164 ohne `+`. `sipid` = Ziel-Extension (Stil `<masterSipId>p0`,
  `p1`, `f0`=Fax …), `mastersipid` = alter Kunde.
- `expires > NOW()` = Row wird serviert (Standard `9999-12-31`); abgelaufene Rows
  sind inaktiv, können aber noch in der Tabelle stehen.
- DDI: enumdns kürzt nicht treffende Nummern bis auf 9 Stellen zur Basenummer —
  bei leerem Resultat ggf. Präfixe mitprüfen.
- Block-Kontext: `WHERE phone LIKE '496002%'` listet alle Rows im Nummernblock.

**Account-Stand (MCP, kein Tunnel):**
- `datapls_helpdesk_search(<Nummer>)` findet den Altkunden — der **Search-Index ist
  Legacy-Stand**, portierte Nummern stehen dort trotzdem noch drin. Nur zur
  masterSipId-Ermittlung.
- `datapls_helpdesk_lookup(master_sip_id, query=numbers)` → `phone_numbers` = **aktuelle
  Wahrheit**: fehlt die Nummer dort, ist der Export account-seitig sauber durch.
  `outgoing[]` zeigt die CLIs der Extensions.
- `query=logs` liefert die Timeline (z.B. Neo-Migration — erklärt ITI-Routing und
  Migrations-Reste in pstn2sip).

### 5. Symptom-Verifikation via HEPIC (optional, wenn Vorfall + Zeitraum bekannt)
`datapls_hepcli call_search(callee=<Nummer>, from/to = enges Fenster, redact=false)`.
Signaturen im Ergebnis (Felder `termcode`, `ruri_user`, `from_user`):

| Beobachtung | Bedeutung |
|---|---|
| eingehende INVITE mit R-URI `+49…;npdi;rn=+49D146<Nummer>@netzquadrat.de` | **Carrier-Portierungsdaten routen zu D146=sipgate**, obwohl die Nummer bei uns abgebaut ist → eingehende Calls kommen an und sterben. Ursache = Portierungsdaten (zentral/nmsd), NICHT ENUM |
| `termcode 487` + 180 Ringing + kurze `ringnc_time` | Call klingelt ins Leere, Anrufer bricht ab — kein Reject |
| NAPTR-basierter intern-Loop (R-URI wird zu `sip:<ext>@sipgate.de` rewritet) | das ENUM-Stale-Bild aus dem Runbook |

Bei Bedarf Detail-Flow: `datapls_hepcli call_transaction(call_id, from, to)` — Antwort
ist groß, per grep auf `rn=` / `ruri_full` auswerten (truncated Output landet in
Temp-Datei, Pfad wird mitgeliefert).

### 6. Befund an den Menschen
Nummer(n) · Routing-Ergebnis · NAPTR-Antwort · pstn2sip-Row(s) · Account-Stand
(phone_numbers!) · ggf. HEPIC-Signatur — aufbereitet abliefern. Ende. Keine
Änderungen, keine Löschungen, keine DELETE-Statements.

## Wenn ENUM sauber ist: nächster Verdacht Portierungsdaten (nmsd/TNB)
Routing=null, keine Row, Calls laufen aber trotzdem zu sipgate / ins Leere →
stale Portierdaten. Zwei Ebenen unterscheiden:
1. **Carrier-Ebene** (zentrale Portierungsdatenbank): erkennbar an `npdi;rn=+49D146`
   in eingehenden INVITEs (Schritt 5) — externe Carrier liefern die Calls bei uns ab.
2. **nmsd-intern**: Safran-Gateway (Yate) löst den TNB via `num2tnb()` / `getTnb()`
   auf den nmsd-Replikas: Kaskade `aknn_routing` → `aknn_data_XX` (XX = erste 2
   Ziffern ohne 49, `active='Y'`) → `aknn_RNB` → Default. `D146` = sipgate — ein
   stale D146-Eintrag reroutet ausgehende Calls intern.
   Hosts `repl-nmsd-01/02.service.sipgate.net`, user `safranro`, DB
   `numberingManagement` — **nicht** via nautilusctl erreichbar, Credentials vaulted
   in `sipgate-deployment/environments/live/group_vars/sip_gateway_safran/`. Repos:
   `~/dev/other/nmsd`, `~/dev/other/safran-yateconfig`.

## Hintergrund (enumdns)
- 10 Live-Hosts `enumdns01-10.live.sipgate.net` + 2 Dev (Perl `sgenum20d`), Anycast
  `217.10.68.155` ist nur von den Resolvern aus erreichbar, nicht direkt vom Client.
- SQL: `SELECT sipid, register_domain, force_billing FROM pstn2sip WHERE phone = ? AND
  expires > NOW() … ORDER BY expires ASC LIMIT 1`.
- RZ-DB-Failover schwenkt nicht automatisch zurück (manueller Restart nötig).
- Repo `~/dev/other/enumdns` (GitHub sipgate/enumdns); TIRP-Response-Formatwechsel
  mon-1817 (08/2026).
- Doku: `~/dev/other/telco-docs/pages/classic-telco/enum-dns/` + `pages/runbooks/enum-dns.md`.

## Kontrollnummern (verifiziert 09/2026)
- `4920392877413`: Routing vorhanden (`3341845p0`), Row aktiv (sipid `3341845p0`,
  mastersipid 3341845) → DNS normal leer; eine positive Antwort = Leak (TIRP-Fehler).
  (Checknummer aus dem enumdns-Nagios-Check.)
- Beliebige ITI-Nummer: Routing da + DNS leer = Normalzustand.

## Verifizierter Real-Fall 09/2026 (Muster für „ENUM sauber, trotzdem kaputt")
Kunde komplett zu Neo migriert (07/2026), danach einzelne Nummern wegportiert.
Account-Phone_numbers sauber, TIRP null, pstn2sip leer — aber eingehende
Carrier-Calls trugen weiterhin `rn=+49D146` und starben bei sipgate (180 + 487
nach ~2 s). Diagnose: Portierungsdaten-Lücke beim Export, nichts zum
ENUM-Cleanup vorhanden. Deren Klärung liegt beim Menschen/Portierungs-Team.
