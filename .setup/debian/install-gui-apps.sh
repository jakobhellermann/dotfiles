#!/bin/bash

set -euo pipefail

DISCORDURL="https://discord.com/api/download?platform=linux&format=deb"

function install_from_url() {
	TEMP_DEB="$(mktemp)"
	wget -O "$TEMP_DEB" "$1"
	sudo dpkg --skip-same-version -i "$TEMP_DEB"
	rm -f "$TEMP_DEB"
}

function install_apt_source_apt_key() {
	curl -sS "$1" | sudo apt-key add -
	echo "deb $2" | sudo tee "/etc/apt/sources.list.d/$3.list"
	sudo apt-get update && sudo apt-get install -y "$4"
}

function install_apt_source() {
	sudo wget -O "/usr/share/keyrings/$3-keyring.gpg" "$1"
	echo "deb [signed-by=/usr/share/keyrings/$3-keyring.gpg] $2" | sudo tee "/etc/apt/sources.list.d/$3.list"
	sudo apt-get update && sudo apt-get install -y "$4"
}

sudo true

command -v discord >/dev/null || install_from_url "$DISCORDURL"
command -v spotify >/dev/null || install_apt_source_apt_key \
	"https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg" "http://repository.spotify.com stable non-free" \
	spotify spotify-client
command -v element-desktop >/dev/null || install_apt_source \
	"https://packages.element.io/debian/element-io-archive-keyring.gpg" "https://packages.element.io/debian/ default main" \
	element-io element-desktop
