#!/bin/bash

set -euo pipefail

sudo pacman -Syu
sudo pacman -S --needed git neovim curl zsh which \
	ripgrep fd jq sd tmux htop exa bat ripgrep fzf wget xclip skim github-cli \
	graphviz imagemagick \
	base-devel mold clang shellcheck rustup

gui=$(test "$#" -gt 0 && test "$1" = "--gui")

$gui && sudo pacman -S --needed noto-fonts firefox kitty gnome-tweaks ttf-jetbrains-mono obsidian discord signal-desktop \
	vulkan-radeon lib32-vulkan-radeon steam
