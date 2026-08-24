---
name: calltest
description: "Telefonie-Verhalten in dev per geschriebenem Test reproduzieren statt Ad-hoc-baresip: Szenario (JUnit + echte baresip-Endpunkte, geräuschlos) in sipgate/neo-telco-tests schreiben und gegen den dev-Cluster laufen lassen. Account-Topologie aus hellermanndeclarativeneo.json (account-provisioning). Use when the user wants a repeatable, scripted dev call test (repro, regression, race-timing) instead of interactive baresip MCP calls."
---

# Telefonie testen per Szenario (neo-telco-tests)

Ziel: ein Telefonszenario **als Code** gegen deployed dev fahren — wiederholbar, geräuschlos (kein
Ton über Lautsprecher, auch keine Wartemusik), mit vollem SIP-Trace im Fail-Fall. Für einmalig
explorative Calls ist der baresip-MCP schneller; für reproduzierbare/regressionsträchtige Fälle
dieser Weg.

## Repo & Voraussetzungen

- Repo: `sipgate/neo-telco-tests` (Klon: `~/dev/bauhaus/neo-telco-tests`). Vor dem Schreiben das
  `AGENTS.md` dort lesen — es erzwingt Regeln (eine @Test-Methode pro Klasse, kein baresip-Import
  in calltest-suites).
- Kotlin 2.4, **Java 25**, Maven multi-module (`./mvnw`). `baresip` muss auf `PATH` liegen.
- Szenarios unter `tests/dev` setzen **echte dev-Calls** ab: nie ohne Aufforderung bzw. ohne
  freigegebenen Account laufen lassen.

## Account: hellermanndeclarativeneo.json

Topologie liegt als Ressource im Repo:
`calltest-suites/src/main/resources/accounts/hellermanndeclarativeneo.json` — der deklarativ
provisionierte Dev-Account **1127920**. Übersicht:

| Alias (JSON) | Art | Extension | Nummer(n) | Direct-Dial |
|---|---|---|---|---|
| `Voiza 1` | voiza | e42 | +4940228170019 | 11 |
| `Voiza 2` | voiza | e40 | +4940228170021 **und** +4940228170022 | 12, 13 |
| `Voiza 3` | voiza | e41 | — | — |
| `VoIP-Telefon von Me Neo` | user device | e43 | — (personal channel: dial 99) | — |

Credentials stehen im JSON. Ändert sich der Account (account-provisioning): JSON im Repo
mit-aktualisieren und committen.

## Szenario schreiben

Ort für Experimente: `tests/dev/wip/` (kann später wieder raus bzw. produktiv in `templates/` +
`tests/dev/<feature>/` aufgeteilt werden). Klassenname endet auf `DevIT`, sonst nimmt ihn der
Make-Filter nicht.

```kotlin
@CallTest
class MeinSzenarioDevIT : CallTestAccounts {
    private val account = readAccountTopology("/accounts/hellermanndeclarativeneo.json")

    override val accounts by lazy {
        agentAccounts {
            devEnvironment()
            agent("alice", account.userDevice("VoIP-Telefon von Me Neo"))
            agent("bob", account.voiza("Voiza 1"))
            // Footgun Voiza 2: ZWEI Nummern -> singleOrNull() liefert null!
            agent("charlie", account.voiza("Voiza 2"), number = "+4940228170021")
        }
    }

    @Test
    fun `beschreibung in einem satz`(
        alice: Agent,
        bob: Agent,
        charlie: Agent,
    ) {
        alice.dial(requireNotNull(bob.number) { "bob needs a number" })
        await untilAsserted { assertThat(bob.callState).isEqualTo(RINGING) }
        bob.answer()
        await untilAsserted { assertThat(alice.callState).isEqualTo(ESTABLISHED) }
        // ...
    }
}
```

Agent-API (nur diese benutzen — ein baresip-Import in calltest-suites ist Compile-Fehler):
`dial`, `answer`, `hangup`, `hold`/`resume`, `transferTo` (Blind-Transfer via REFER),
`sendDtmf`, `addHeader`, `setTone`, `recordReceivedAudio`; beobachten per `callState`,
`closeReason`, `closeStatus`, `events`, `sipTrace()`.

Regeln aus der Praxis:

- **Genau eine @Test-Methode pro Klasse** (erzwungen, Run failt sonst). Sweep/Loops gehören in
  die eine Methode, nicht in mehrere Tests.
- **Warten immer per Awaitility** auf `callState`/`events`, nie `Thread.sleep` — einzige
  Ausnahme: bewusste Race-Injektion (z.B. Gap zwischen `hold()` und `transferTo`, siehe
  Referenzszenario).
- **Ein Agent trägt einen Call gleichzeitig**, kann nach `CLOSED` aber wieder dialen (sequenzielle
  Calls im Loop sind ok).
- **Devices gehören dem Szenario**: keine Extension zweimal in verschiedenen Klassen belegen —
  `make dev` läuft die Klassen parallel. Vor dem Schreiben kurz greppen, wer e40–e43 schon nutzt
  (derzeit nutzt `HardwareBlindTransferDuringHoldRaceDevIT` im wip-Ordner e42/e40/e43).
- **Nummern-Footgun**: `agent(name, device)` nimmt `numbers.singleOrNull()` — bei Geräten mit
  zwei Nummern (Voiza 2) explizit `number = …` übergeben, sonst transferiert `transferTo` auf
  die AOR und die Platform lehnt mit 603 Decline ab.
- **Agenten sind stumm**: Töne gehen als RTP-Ton raus, Empfangenes in aufile-Dateien — weder
  Rufton noch MoH kommen aus den Lautsprechern des Rechners.

## Ausführen & Lesen der Ergebnisse

```bash
# ein Szenario (echte dev-Calls!):
make dev.MeinSzenarioDevIT

# alle dev-Szenarien (parallel):
make dev

# nur kompilieren/formatieren, ohne Calls:
make check
```

- Reports: eine Datei pro Klasse unter `calltest-suites/target/failsafe-reports/` — bei Failure
  hängt der komplette SIP-Trace + Agent-Log direkt an der Assertion (nicht das Maven-Stdout
  greppen).
- Vor dem Committen: `./mvnw spotless:apply` (läuft auch im pre-commit hook).

## Referenzszenario

`tests/dev/wip/HardwareBlindTransferDuringHoldRaceDevIT.kt` (BAUHAUS-3293): Anruf alice→bob, bob
holdet und blind-transfert zu charlie, mit Gap-Sweep zwischen `hold()` und `transferTo()` — inkl.
Race-Injektion per `Thread.sleep` und Bug-Detection über `callState`/`closeReason` (Session-Kill
= Call stirbt ohne BYE). Als Vorlage für eigene Szenarien geeignet.

## Abgrenzung

- Lokal laufender Service gegen dev-Infra ohne Deploy → Skill `local-call-test`.
- Interaktive Einzel-Calls („klingelt das Gerät?") → baresip-MCP.
- Deterministischer Test der pbxcore-Interna (Journal-Race etc.) → IT in pbxcore-telco-service.
