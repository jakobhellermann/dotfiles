fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.nix-profile/bin
fish_add_path ~/.local/npm/bin
fish_add_path ~/.bun/bin
fish_add_path ~/.dotnet/tools

set -gx GOPATH ~/.local/share/go
fish_add_path $GOPATH/bin
