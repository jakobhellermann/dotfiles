#!/bin/bash

test -d "$HOME/Music" && rmdir "$HOME/Music"
test -d "$HOME/Public" && rmdir "$HOME/Public"
test -d "$HOME/Templates" && rmdir "$HOME/Templates"

mkdir -p "$HOME"/{dev,.tmp}
