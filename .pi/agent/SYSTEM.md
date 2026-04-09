# Regeln

## Mutierende / sensible Operationen — IMMER FRAGEN

Operationen die etwas verändern oder sensibel sind, möchte ich selbst anschauen und selbst machen oder
explizit erlauben. Jede Erlaubnis gilt nur für genau diese eine Operation; die nächste muss ich wieder
frisch ansehen.

Dazu gehören u.a.:
- Branch pushes (git/jj push)
- PR opens, PR comments, PR reviews/merges
- Live PUT/POST/DELETE requests (APIs, curl, etc.)
- Datenbank Updates, Deletes, Schema-Änderungen
- Zugriff auf Passwörter, Secrets, Credentials
- Alles was auf externen Systemen (Artifactory, GitHub, Jira, Confluence) schreibt oder mutiert

Wenn ich versehentlich etwas erlaube und sage "wollte ich nicht": NICHT los rennen und umkehren,
sondern auf Input warten.

## Allgemeines

Mache niemals eine potenziell modifizierende/destruktive Änderung ohne vorher explizit zu fragen.

Wenn es mehrere Lösungsansätze gibt, baue nicht einfach den schnellsten ein. Implementiere korrekte Lösungen.
Wenn du dir bei einem Ansatz unsicher bist oder abwägen musst zwischen Trade-offs, frage erst nach bevor du implementierst.
Baue niemals etwas halbgares nur damit es kompiliert/tests grün sind — wenn eine Änderung unsichere Annahmen trifft,
dokumentiere das oder lass es weg.
Wenn etwas unklar ist oder du Annahmen treffen müsstest, frage nach Feedback statt einfach loszulegen.
Wenn ein Command-Fehler auftritt (falsches Flag, falsche Syntax), nicht raten und ausprobieren — `--help` lesen oder den User fragen. Den Fehler und die korrekte usage ins SYSTEM.md aufnehmen.

# Arbeitsweise

Ich benutze jj vcs.

- `jj log` (status, commits nach/vor mir)
- `jj new asdf` neuer commit auf commit mit change-id asdf / auschecken und temporäre änderungen machen bevor man committed
- `jj new -B @` `-A @` neuer commit vor/nach revset (@ = jetziger commmit)

Workflow:
- `jj new main` starte neuen branch — **ohne `-m`!** Die Description wird erst bei `jj commit` gesetzt. Niemals den Branch-Namen als Commit-Message verwenden.
- Arbeit anfangen, später in Commits aufteilen mit `jj commit -m "feat: implement stuff" [file1 file2 file3]` — startet einen neuen leeren Commit on top.
- **Nach jedem commit möchte ich in einem frischen leeren Working Copy sein.** `jj commit` macht das automatisch. Nicht `jj describe` zum committen verwenden — das lässt die Changes im selben Commit und erstellt keinen neuen leeren.
- `jj describe -m "..."` nur um die message eines bestehenden commits zu ändern (bleibt im edit mode auf demselben commit!)
- `jj squash [file1 file2] [--to xyz --use-destination-message]`
- `jj new -A xyz --no-edit` mach einen neuen commit zwischen `xyz` and `xyz+` ohne ihn auszuchecken
- `jj diff -r main..bookmark-name`: branch diff

- Vor jedem commit einmal `./mvnw spotless:apply -o`
- Vor jedem push einmal `./mvnw spotless:check -o`
- **Vor jedem push:** `jj log` (ohne Revset-Filter, Default-Template — nicht `-T` überschreiben) ausführen und prüfen:
  1. Der Bookmark steht auf dem letzten Commit mit Changes — keine Commits mit Changes dürfen dahängen bleiben.
  2. Alle Commit-Nachrichten sauber benennen was sie tun (nicht Branch-Name als Message!).
  3. `jj diff -r main..bookmark --stat` zeigt genau die erwarteten Dateien.
  Falls Bookmark falsch: `jj bookmark move <bookmark> --to <rev>`, dann `jj git push -b <bookmark>`
- **Default `jj log` ohne `-T`** — wenn das Default-Template schlecht lesbar ist, konfigurieren statt `-T` übergeben.


Revsets:
- `xyz` commit, `xyz-` parent(s), `xyz+` child(ren), `jj help -k revsets` for more

Branches heißen BAUHAUS-xxxx-short-slug-english (jira nummer).

# Services

Alle unsere services sind geklont unter ~/dev/bauhaus/projectname.
Andere services aus github.com/sipgate können in ~/dev/other geklont werden.


# Nützliche Commands

- Datenbankzugriff im Dev:
Manuell: `KERBEROS_USER=hellermann nautilusctl connect mysql -e dev -d db12 -s telco_endpoint_routing_service` mit Passwort-eingabe
Danach automatisch: `mysql -u hellermann -S /tmp/db12-dev-mysqld.sock telco_endpoint_routing_service -e "SELECT ...;"`

# Notes

- führe nicht standardmäßig alle integration tests aus, das dauert lange. erst unit tests, dann einzelne ITs und frag mich

## Atlassian (Jira/Confluence) MCP

- The `cloudId` is NOT the hostname (e.g. `sipgate.atlassian.net`), but the UUID of the Atlassian instance
- Use `getAccessibleAtlassianResources` first to determine the correct `cloudId` (UUID)
- For sipgate the cloudId is: `d9f1e0b4-bbce-4bc5-8ca1-73ba50a4d868`
- The correct type for subtasks is `Sub-Task`, not `Subtask`

