#!/bin/bash

set -euo pipefail

sudo pacman -Syu
sudo pacman -S --needed git neovim curl zsh which \
	ripgrep fd jq tmux htop exa bat ripgrep fzf wget xclip \
	ripgrep fd jq tmux htop exa bat ripgrep fzf wget xclip \
	graphviz imagemagick \
	base-devel mold clang shellcheck rustup

gui=$(test "$#" -gt 0 && test "$1" = "--gui")

$gui && sudo pacman -S --needed kitty gnome-tweaks ttf-jetbrains-mono obsidian \
	vulkan-radeon lib32-vulkan-radeon steam
