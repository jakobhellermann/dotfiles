#!/bin/bash

set -euo pipefail

install_paru() {
	pushd $(mktemp -d)
	git clone https://aur.archlinux.org/paru.git
	cd paru
	makepkg -si
	popd
}
command -v paru >/dev/null || install_paru

paru -S --needed spotify jetbrains-fleet
