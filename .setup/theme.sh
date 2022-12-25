#!/bin/bash

set -euo pipefail

function install_from_url() {
	TEMP_DEB="$(mktemp)"
	wget -O "$TEMP_DEB" "$1"
	sudo dpkg --skip-same-version -i "$TEMP_DEB"
	rm -f "$TEMP_DEB"
}

# install_from_url https://launchpad.net/~regolith-linux/+archive/ubuntu/stable/+files/ayu-theme_0.2.0-1ubuntu1~ppa1_amd64.deb
# gsettings set org.gnome.desktop.interface gtk-theme 'Ayu-Mirage-Dark'

# gsettings set org.gnome.desktop.interface gtk-theme 'Pop-dark'

sudo apt install -y papirus-icon-theme
gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
