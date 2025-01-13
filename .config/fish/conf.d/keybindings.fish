# set fish_key_bindings fish_hybrid_key_bindings
# 
abbr -a fish-reload-config 'source ~/.config/fish/**/*.fish'

bind -M insert \e\[A history-prefix-search-backward
bind -M insert \e\[B history-prefix-search-forward

bind \ct -M insert 'commandline -i (fd --hidden --max-depth 4 | fzf | tr -d \n)'
bind \cw -M insert 'commandline -r; commandline (fd --type d --hidden --max-depth 4 | fzf); commandline -f execute'
