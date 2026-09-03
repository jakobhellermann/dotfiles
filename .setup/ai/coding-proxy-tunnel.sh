#!/bin/bash
# Forward the sipgate coding proxy to the Windows machine over the private tailnet.
# Start manually on the mac (no autostart); Ctrl-C stops it.
set -euo pipefail

REMOTE=jakob@100.71.131.126 # desktop-79044jr, tailscale IP
HOST=coding-proxy.nautilus-tooling01.live.ix01.sipgate.net
KEY="$HOME/.ssh/id_ed25519_win_forward"

if pgrep -f "ssh -N -R 127.0.0.1:443:$HOST" >/dev/null; then
	echo "tunnel already running (stop: pkill -f 'ssh -N -R 127.0.0.1:443')"
	exit 0
fi

exec ssh -N -R "127.0.0.1:443:$HOST:443" \
	-i "$KEY" \
	-o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
	-o ExitOnForwardFailure=yes \
	"$REMOTE"
