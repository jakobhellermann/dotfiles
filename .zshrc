# oh-my-zsh config
ZSH_CACHE_DIR=""
case $(uname) in
  Darwin) ZSH_CACHE_DIR="$HOME/Library/Caches/zsh";;
  Linux) ZSH_CACHE_DIR="$HOME/.cache/zsh";;
esac

plugins=( git colored-man-pages extract dotenv fzf )

ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
HISTFILE="$ZSH_CACHE_DIR/.zsh_history"
ZSH="$HOME/.oh-my-zsh"
DISABLE_AUTO_UPDATE=true
DISABLE_AUTO_TITLE=true

source "$ZSH/oh-my-zsh.sh"

# user config
configs=("$HOME/.env" "$HOME/.env.local" "$HOME/.aliases")
scripts=("$HOME/.local/share/zsh/jjsimple.zsh-theme" "$HOME/.fzf/shell/key-bindings.zsh")
evalcmds=("zoxide init zsh")

hostname=${$(hostnamectl hostname):r}
for c in $configs; do
	[[ -f "$c.$hostname" ]] && source "$c.$hostname"
	[[ -f "$c" ]] && source "$c"
done

for s in $scripts; do
	[[ -f "$s" ]] && source "$s"
done

for cmd in $evalcmds; do
	if command -v "${cmd%% *}" >/dev/null; then
		eval "$(eval $cmd)"
	fi
done

test -d "$HOME/.zshrc.d" && for file in $(ls "$HOME/.zshrc.d"); do
	echo "$file"
done

true
