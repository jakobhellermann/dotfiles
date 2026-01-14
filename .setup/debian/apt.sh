#!/bin/bash

set -euo pipefail

APT_SOURCES_FILE=/etc/apt/sources.list.d/system.sources

test -f "$APT_SOURCES_FILE" && sudo sed 's/us/de/' -i "$APT_SOURCES_FILE"
sudo apt update

sudo apt install -y git neovim curl ripgrep fd-find jq zsh fzf
sudo apt install -y tmux autojump htop graphviz librsvg2-bin imagemagick shellcheck
sudo apt install -y -o Dpkg::Options::="--force-overwrite" bat ripgrep
sudo apt install -y libssl-dev lld clang

gui=$(test "$#" -gt 0 && test "$1" = "--gui")

$gui && sudo apt install -y kitty gnome-tweaks fonts-jetbrains-mono

install_mold_linker() {
	sudo apt-get install -y build-essential git clang cmake libstdc++-10-dev libssl-dev libxxhash-dev zlib1g-dev
	pushd $(mktemp -d)
	git clone https://github.com/rui314/mold.git
	cd mold
	git checkout v0.9.6
	make -j$(nproc)
	sudo make install
	popd
}
command -v mold >/dev/null || install_mold_linker
