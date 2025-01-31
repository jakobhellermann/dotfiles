abbr -a fish-reload-config 'source ~/.config/fish/**/*.fish'

bind -M insert \e\[A history-prefix-search-backward
bind -M insert \e\[B history-prefix-search-forward

function interactive-picker
    if set res (fd --hidden --max-depth 10 | fzf)

        set cli (commandline)

        test -z $cli -a -f "$res" && commandline -i "vim "

        string match -qr '( $)|^$' $cli || commandline -i " "

        commandline -i "$res"
        commandline -f execute

    end
end
bind \cw -M insert interactive-picker
