- don't guess my intentions, ask for clarifications if necessary
- never commit to vcs or do destructive actions without asking first
- comments always in english, even if i talk in german
- instead of piping long-running processes directly to grep, tee them to a file and grep afterwards
- If a command line tool is helpful but not installed, ask me if I want to install it.
- never assert a fact without validating it first with all tools you have at hand.
I'd rather take 30 minutes to understand why something fails, than continue with a guess immediately.

# VCS

I'm using jj as my vcs, with full git compatibility.

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

Use single-line commit messages without co-authored-by by default, unless i ask for more context.

Commit message style: a SHORT imperative header (match the repo's existing style), then — when more context
helps — a blank line and a brief body of a few sentences. Do NOT cram everything into one long run-on header
line (no novels). Header says what; body says why / the key mechanism.



# Arbeitsweise

Fang nicht einfach an drauf los zu implementieren. Versuch bugs zu verstehen,
mit allen tools an deiner hand. Dann besprechen wir die Lösung, und debuggen weiter.
Erst wenn wir eine klare Umestzungsidee haben, wird implementiert.

Danach validieren wir den fix, und danach wird committed.
