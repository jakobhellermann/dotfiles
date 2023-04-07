#!/bin/sh

lookandfeeltool --apply org.kde.breezedark.desktop
kwriteconfig5 --file "$HOME/.config/kwinrc" --group MouseBindings --key CommandAllKey Alt
kwriteconfig5 --file "$HOME/.config/kwinrc" --group TabBox --key LayoutName compact
kwriteconfig5 --file "$HOME/.config/kwinrc" --group TabBox --key HighlightWindows false

kwriteconfig5 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatRate 30
kwriteconfig5 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatDelay 250

kwriteconfig5 --file "$HOME/.config/krunnerrc" --group General --key FreeFloating true
