#!/bin/bash

set -euo pipefail

sudo pacman -S --needed git neovim curl zsh which \
	ripgrep bat dust fd sd jq skim htop eza ripgrep fzf github-cli rsync \
	graphviz imagemagick unzip \
	base-devel mold clang shellcheck rustup bacon inotify-tools

gui=$(test "$#" -gt 0 && test "$1" = "--gui")
$gui && sudo pacman -S --needed wl-clipboard noto-fonts firefox foot ttf-jetbrains-mono obsidian discord signal-desktop

multilib=$(test "$#" -gt 1 && test "$2" = "--multilib")
$multilib && sudo pacman -S --needed vulkan-radeon lib32-vulkan-radeon steam
