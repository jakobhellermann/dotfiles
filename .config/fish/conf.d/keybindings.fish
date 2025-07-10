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
bind \cq -M insert interactive-picker

function bind_bang
    switch (commandline -t)[-1]
        case "!"
            commandline -t -- $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function bind_dollar
    switch (commandline -t)[-1]
        case "!"
            commandline -f backward-delete-char history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

bind -M insert '!' bind_bang
bind -M insert '$' bind_dollar
