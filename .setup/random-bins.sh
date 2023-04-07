#!/bin/bash

set -euo pipefail

files=('https://raw.githubusercontent.com/mneri/pnglatex/master/pnglatex')

for file in "${files[@]}"; do
	wget --quiet --no-clobber --directory-prefix "$HOME/.local/bin" "$file"
	sudo chmod +x "$HOME/.local/bin/$(basename "$file")"
done
