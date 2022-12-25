#!/bin/sh

# keyboard
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
# gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps', 'lv3:lalt_switch', 'apple:badmap']"
# gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

# mouse
gsettings set org.gnome.desktop.peripherals.mouse speed "-0.65"

gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
gsettings set org.gnome.desktop.peripherals.keyboard delay 250

# shortcuts
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>Q']"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>f']"

# audio
gsettings set org.gnome.desktop.wm.preferences audible-bell false

# default apps
gsettings set org.gnome.desktop.default-applications.terminal exec kitty
gsettings set org.gnome.desktop.default-applications.terminal exec-arg ""

# style
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,close'
# gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
# gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
