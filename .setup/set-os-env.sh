#!/bin/bash

set -eo pipefail

enable_macos_theme() {
	theme="WhiteSur-${1:-dark}"

	gsettings set org.gnome.desktop.interface gtk-theme "$theme"
	gsettings set org.gnome.desktop.interface icon-theme "$theme"

	gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/wallpapers/macOS-Big-Sur.jpg"

	gnome-extensions enable dash-to-dock@micxgx.gmail.com
	dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
}

enable_pop_theme() {
	gsettings set org.gnome.desktop.interface gtk-theme Pop-dark # Adwaita-dark
	gsettings set org.gnome.desktop.interface icon-theme Pop

	gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/wallpapers/RetroSunset.png"

	gnome-extensions disable dash-to-dock@micxgx.gmail.com
}

case "$1" in
"mac")
	enable_macos_theme "$2"
	;;
"pop")
	enable_pop_theme "$2"
	;;
*)
	echo "expected mac or pop, got '$1'"
	;;
esac
