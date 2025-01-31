type -q fnm && fnm env | source

if status is-interactive
    set fish_key_bindings fish_hybrid_key_bindings
    set fish_cursor_unknown line
    set fish_cursor_normal block
    set fish_cursor_default block
    set fish_greeting

    set -gx LIBRARY_PATH "$HOME/.nix-profile/lib"

    type -q pay-respects && pay-respects fish --alias --nocnf | source
    test -f /opt/homebrew/bin/brew && /opt/homebrew/bin/brew shellenv | source
end

# pnpm
set -gx PNPM_HOME "$HOME/.cache/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Ensure nix packages have priority over system binaries
fish_add_path --prepend --move ~/.nix-profile/bin
