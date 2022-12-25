# ~/.bashrc

[[ $- != *i* ]] && return

os=$(uname | tr '[:upper:]' '[:lower:]')

extensions=("$HOME/.env" "$HOME/.aliases" )

for p in "${extensions[@]}"; do
	[[ -f "$p.$os" ]] && source "$p.$os"
	[[ -f "$p" ]] && source "$p"
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
