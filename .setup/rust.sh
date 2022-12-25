#!/bin/bash

set -euo pipefail

command -v cargo >/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source "$HOME/.cargo/env"

cargo install \
	skim exa sd du-dust topgrade skim \
	cargo-watch cargo-outdated cargo-expand cargo-whatfeatures cargo-asm cargo-llvm-lines
