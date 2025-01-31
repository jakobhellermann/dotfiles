- use context7 mcp server to look up-to-date info, docs and versions
- don't guess my intentions, ask for clarifications if necessary
- before removing or changing asserts, think about whether the actual code should change instead or ask me
- never commit to vcs or do destructive actions without asking first
- comments always in english, even if i talk in german
- prefer asserting full matches, i.e. assertEqual instead of assering not empty or contains
- instead of piping long-running processes directly to grep, tee them to a file and grep afterwards
- use double dollars to escape properties in spring kotlin: `@Value($$"${config.path.to.var}") private val foo: String`
- prefer git WIP commits over stashes
- prefer git switch over checkout
- dont use sdkman, use my global java/maven install

- Use the my-grafana-subagent for all Grafana operations (logs, metrics, dashboards)



# Regeln

Mache niemals eine potenziell modifizierende/destruktive Änderung wie Datenbank Updates, Deletes, curl -X DELETE/PUT ohne vorher
explizit zu fragen.

# Arbeitsweise

Ich benutze jj vcs.

- `jj log` (status, commits nach/vor mir)
- `jj new asdf` neuer commit auf commit mit change-id asdf / auschecken und temporäre änderungen machen bevor man committed
- `jj new -B @` `-A @` neuer commit vor/nach revset (@ = jetziger commmit)

Workflow:
- `jj new main` starte neuen branch
- `jj commit -m "feat: implement stuff" [file1 file2 file3]` create a new commit as parent from the changes
- `jj squash [file1 file2] [--to xyz --use-destination-message]`
- `jj new -A xyz --no-edit` mach einen neuen commit zwischen `xyz` and `xyz+` ohne ihn auszuchecken
- `jj diff -r main..bookmark-name`: branch diff

- Vor jedem commit einmal `./mvnw spotless:apply -o`
- Vor jedem push einmal `./mvnw spotless:check -o`


Revsets:
- `xyz` commit, `xyz-` parent(s), `xyz+` child(ren), `jj help -k revsets` for more

Branches heißen BAUHAUS-xxxx-short-slug-english (jira nummer).

# Services

Alle unsere services sind geklont unter ~/dev/bauhaus/projectname.
Andere services aus github.com/sipgate können in ~/dev/other geklont werden.


# Nützliche Commands

- Datenbankzugriff im Dev:
Manuell MySQL: `KERBEROS_USER=hellermann nautilusctl connect mysql -e dev -d db12 -s telco_endpoint_routing_service` (Passwort-Prompt, kein `-f` Flag verfügbar — Passwort aus 1Password via `op read "op://Employee/nautilusctl db/password"`)
Postgres ohne Prompt: `nautilusctl connect postgres -e live -r <service> -l ix01 -f ~/.local/share/scripts/nautilusctl-password` (das Script macht `op read "op://Employee/nautilusctl db/password"`)
Danach automatisch: `mysql -u hellermann -S /tmp/db12-dev-mysqld.sock telco_endpoint_routing_service -e "SELECT ...;"`

z.B. db05-replica01 für ser db

# Notes

- führe nicht standardmäßig alle integration tests aus, das dauert lange. erst unit tests, dann einzelne ITs und frag mich
