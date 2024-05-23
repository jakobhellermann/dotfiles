#!/usr/bin/env bash

if [ $# -ne 0 ]; then
	notify-send "$ROFI_INFO"
	$ROFI_INFO
	exit 0
fi

option() {
	echo -en "$1\0info\x1f$2\n"
}

option Shutdown 'systemctl poweroff'
option Reboot 'systemctl reboot'
option Logout 'swaymsg exit'
option Suspend 'systemctl suspend'
