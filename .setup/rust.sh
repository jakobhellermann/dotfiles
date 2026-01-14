#!/bin/bash

set -euo pipefail

command -v cargo >/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

test -f "$HOME/.cargo/env" && source "$HOME/.cargo/env"

crates=(cargo-watch cargo-outdated cargo-expand cargo-whatfeatures cargo-asm cargo-llvm-lines cargo-nextest cargo-hack)
uninstalled=()

for crate in "${crates[@]}"; do
	command -v "$crate" >/dev/null || uninstalled+=("$crate")
done

cargo install "${uninstalled[@]}"
