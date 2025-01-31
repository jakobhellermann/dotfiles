# ~/.bashrc

[[ $- != *i* ]] && return

os=$(uname | tr '[:upper:]' '[:lower:]')

configs=("$HOME/.env" "$HOME/.aliases" )
evalcmds=("fnm env")

for p in "${configs[@]}"; do
	[[ -f "$p.$os" ]] && source "$p.$os"
	[[ -f "$p" ]] && source "$p"
done

for cmd in "${evalcmds[@]}"; do
    if command -v "${cmd%% *}" >/dev/null 2>&1; then
        eval "$($cmd)"
    fi
done

PROMPT_DIRTRIM=1
PS1=" \[\e[0;36m\]\w \
\$(if [[ \$? -gt 0 ]]; then printf \"\\[\\e[0;35m\\]\"; else printf \"\\[\\e[0;34m\\]\"; fi)\
λ \[\e[0m\]"

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"


if [ -f /usr/share/bash-completion/bash_completion ]; then
. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
. /etc/bash_completion
fi
source /Users/sipgatejj/.sdkman/bin/sdkman-init.sh
