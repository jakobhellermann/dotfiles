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
