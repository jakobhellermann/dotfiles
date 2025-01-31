#!/bin/sh

lookandfeeltool --apply org.kde.breezedark.desktop
kwriteconfig6 --file "$HOME/.config/kwinrc" --group MouseBindings --key CommandAllKey Alt
kwriteconfig6 --file "$HOME/.config/kwinrc" --group TabBox --key LayoutName compact
kwriteconfig6 --file "$HOME/.config/kwinrc" --group TabBox --key HighlightWindows false
kwriteconfig6 --file "$HOME/.config/kwinrc" --group kwin --key Plugins slideEnabled false
kwriteconfig6 --file "$HOME/.config/kwinrc" --group kwin --key Plugins fadedesktopEnabled false

kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatRate 30
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatDelay 200

kwriteconfig6 --file "$HOME/.config/krunnerrc" --group General --key FreeFloating true

kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group services --group kitty.desktop --key _launch "Alt+Shift+T,Alt+Enter"
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group services --group firefox.desktop --key _launch "Alt+F"
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key 'Window Close' "Alt+Q,Alt+F4,Close Window"
