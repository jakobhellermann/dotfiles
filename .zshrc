function () {

# oh-my-zsh
ZSH_CACHE_DIR=""
case $(uname) in
  Darwin) ZSH_CACHE_DIR="$HOME/Library/Caches/zsh";;
  Linux) ZSH_CACHE_DIR="$HOME/.cache/zsh";;
esac

ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
HISTFILE="$ZSH_CACHE_DIR/.zsh_history"
ZSH="$HOME/.oh-my-zsh"
DISABLE_AUTO_UPDATE=true
DISABLE_AUTO_TITLE=true

plugins=( git colored-man-pages extract dotenv fzf )
source "$ZSH/oh-my-zsh.sh"

# user config
local configs=("$HOME/.env" "$HOME/.aliases")
local scripts=(
	"$HOME/.local/share/zsh/jjsimple.zsh-theme"
	"$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
	# "$HOME/.sdkman/bin/sdkman-init.sh"
)
local evalcmds=(
	"zoxide init zsh"
	"fnm env"
	"fasder --init auto aliases"
)

local hostname=$(hostnamectl hostname)
for c in $configs; do
	[[ -f "$c" ]] && source "$c"
	[[ -f "$c.$hostname" ]] && source "$c.$hostname"
done

for s in $scripts; do
	[[ -f "$s" ]] && source "$s"
done

for cmd in $evalcmds; do
	if command -v "${cmd%% *}" >/dev/null; then
		eval "$(eval $cmd)"
	fi
done
unfunction jj

test -d "$HOME/.zshrc.d" && for file in "$HOME/.zshrc.d"/*(N); do
	source "$file"
done

TRAPUSR1() { rehash; }
true

}
