type -q fnm && fnm env | source

if status is-interactive
    set fish_key_bindings fish_hybrid_key_bindings
    set fish_cursor_unknown line
    set fish_cursor_normal block
    set fish_cursor_default block
    set fish_greeting

    type -q pay-respects && pay-respects fish --alias --nocnf | source
end

# pnpm
set -gx PNPM_HOME /Users/sipgatejj/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
