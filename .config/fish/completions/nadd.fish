function __nadd_complete
    set -l token (commandline -ct)
    # `nix profile add` crashes the completer, so use the `install` alias.
    # Words: nix(0) profile(1) install(2) nixpkgs#TOKEN(3)
    NIX_GET_COMPLETIONS=3 nix profile install "nixpkgs#$token" 2>/dev/null |
        tail -n +2 |
        string replace -r '^nixpkgs#' ''
end

complete -c nadd -f -a '(__nadd_complete)'
