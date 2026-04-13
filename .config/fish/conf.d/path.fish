fish_add_path -g ~/.local/bin
fish_add_path -g ~/.cargo/bin
fish_add_path -g ~/.local/npm/bin
fish_add_path -g ~/.bun/bin
fish_add_path -g ~/.dotnet/tools

set -gx GOPATH ~/.local/share/go
fish_add_path -g $GOPATH/bin

test -d /usr/lib/qt6/bin && fish_add_path -g /usr/lib/qt6/bin
