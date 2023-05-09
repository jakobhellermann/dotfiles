#!/bin/bash

set -euo pipefail

sudo pacman -S --needed git neovim curl zsh which \
	ripgrep fd jq sd tmux htop exa bat ripgrep fzf wget xclip skim github-cli \
	graphviz imagemagick unzip \
	base-devel mold clang shellcheck rustup

gui=$(test "$#" -gt 0 && test "$1" = "--gui")
$gui && sudo pacman -S --needed wl-clipboard noto-fonts firefox kitty ttf-jetbrains-mono obsidian discord signal-desktop

multilib=$(test "$#" -gt 0 && test "$1" = "--multilib")
$multilib && sudo pacman -S --needed vulkan-radeon lib32-vulkan-radeon steam
