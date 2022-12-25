#!/bin/bash

FIREFOX_PATH="$HOME/.mozilla/firefox"

default_profile() {
	profile=$(grep Default "$FIREFOX_PATH/profiles.ini" | head -n 1 | cut -d '=' -f 2)
	echo "$FIREFOX_PATH/$profile"
}

install_chrome_userstyles() {
	echo "install userstyle 'MaterialFox' (--no-chrome to disable)"
	profile_path=$1

	tmpdir=$(mktemp -d)
	git clone https://github.com/muckSponge/MaterialFox "$tmpdir"

	cp -r "$tmpdir/chrome" "$tmpdir/user.js" "$profile_path"
}

profile_path=$(default_profile)

echo "$profile_path"

rm -rf "$profile_path/chrome" "$profile_path/user.js"
mkdir "$profile_path/chrome"

[ "$1" != "--no-chrome" ] && install_chrome_userstyles "$profile_path"

echo 'set dark theme'
{
	echo ''
	echo 'user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");'
	echo 'user_pref("devtools.theme", "dark");'
} >>"$profile_path/user.js"
