# set fish_key_bindings fish_hybrid_key_bindings

abbr -a fish-reload-config 'source ~/.config/fish/**/*.fish'

bind -M insert \e\[A history-prefix-search-backward
bind -M insert \e\[B history-prefix-search-forward

bind \cw -M insert 'if set res (fd --hidden --max-depth 5 | fzf); test -z (commandline) -a -f "$res" && commandline -i "vim "; commandline -i "$res"; commandline -f execute; end'
bind \ct -M insert 'if set res (fd --hidden --max-depth 5 | fzf); test -z (commandline) -a -f "$res" && commandline -i "vim "; commandline -i "$res"; commandline -f execute; end'
