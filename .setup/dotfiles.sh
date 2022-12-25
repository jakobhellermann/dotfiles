#!/bin/bash

set -euo pipefail

GIT_DIR="$HOME/.dotfiles"
WORK_TREE="$HOME"

rm -f "$HOME/.bashrc"
git --work-tree "$WORK_TREE" clone --bare https://github.com/jakobhellermann/dotfiles.git "$GIT_DIR"
git --git-dir "$GIT_DIR" --work-tree "$WORK_TREE" checkout

if [ $? = 0 ]; then
	echo "Checked out config."
else
	exit 1
fi

git --git-dir "$GIT_DIR" --work-tree "$WORK_TREE" config status.showUntrackedFiles no
