type -q fnm && fnm env | source

if status is-interactive
    set fish_key_bindings fish_hybrid_key_bindings
    set fish_cursor_unknown line
    set fish_cursor_normal block
    set fish_cursor_default block
    set fish_greeting

    type -q pay-respects && pay-respects fish --alias --nocnf | source

    complete -c './mvnw' -w mvn
    complete -c './gradlew' -w gradle
end

# pnpm
set -gx PNPM_HOME "$HOME/.cache/pnpm"
fish_add_path --move "$PNPM_HOME/bin" "$PNPM_HOME"
# pnpm end

direnv hook fish | source
