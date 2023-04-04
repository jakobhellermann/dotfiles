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

fpath+=~/.zfunc

source "$ZSH/oh-my-zsh.sh"

# user config
configs=("$HOME/.env" "$HOME/.env.local" "$HOME/.aliases")
scripts=("$HOME/.local/share/zsh/jjsimple.zsh-theme" "$HOME/.fzf/shell/key-bindings.zsh")

hostname=${$(hostnamectl hostname):r}
for c in $configs; do
	[[ -f "$c.$hostname" ]] && source "$c.$hostname"
	[[ -f "$c" ]] && source "$c"
done

for s in $scripts; do
	[[ -f "$s" ]] && source "$s"
done

command -v zoxide>/dev/null && eval "$(zoxide init zsh)"

true
