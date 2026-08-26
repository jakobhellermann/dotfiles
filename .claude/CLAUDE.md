- use context7 mcp server to look up-to-date info, docs and versions
- don't guess my intentions, ask for clarifications if necessary
- before removing or changing asserts, think about whether the actual code should change instead or ask me
- fail loud, don't silently swallow errors: surface or throw at the point of failure instead of catching-and-ignoring, defaulting away the problem, or degrading quietly. no empty/log-only catch blocks that swallow, no silent fallbacks that hide a real error, no "forgiving"/"ignore errors" flags chosen to avoid a crash. if a fallback is genuinely wanted, make it explicit and loud (or ask me) — don't reach for it by default
- never commit to vcs or do destructive actions without asking first
- don't write details of my local environment into public repos (e.g. workarounds for my global ~/.cargo/config.toml, personal paths, machine-specific tooling). fix such things in my local setup, not in shared/committed files.
- never read decrypted secrets into the conversation: don't `cat` rendered config files under /run, /etc/agenix, systemd `LoadCredential` paths, or anything an agenix/sops/systemd service decrypts at runtime. if you need to inspect such a file, redact first (e.g. `jq 'del(..|.token?,.password?)'`) or just describe the structure
- comments always in english, even if i talk in german
- prefer asserting full matches, i.e. assertEqual instead of assering not empty or contains
- instead of piping long-running processes directly to grep, tee them to a file and grep afterwards
- use double dollars to escape properties in spring kotlin: `@Value($$"${config.path.to.var}") private val foo: String`
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
