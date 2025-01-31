#!/bin/bash

FIREFOX_PATH="$HOME/.mozilla/firefox"

default_profile() {
	profile=$(grep Default "$FIREFOX_PATH/profiles.ini" | head -n 1 | cut -d '=' -f 2)
	echo "$FIREFOX_PATH/$profile"
}
profile_path=$(default_profile)

cat <<-EOF >"$profile_path/user.js"
	user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
	user_pref("ui.menuAccessKey", 0);
	user_pref("signon.rememberSignons", false);
	user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
EOF
