#!/bin/sh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mkdir "$HOME/.cache/zsh"

mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
rm "$HOME/.shell.pre-oh-my-zsh"
