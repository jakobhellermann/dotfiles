#!/bin/bash
# One-time setup for the coding-proxy tunnel client on Linux.
# Unlike windows, the tunnel is PULLED: a root systemd service here opens
# ssh -L to the mac (sshd already runs there over tailscale), so this
# machine needs no sshd and binds 443 as root.
# Run as your normal user; sudo is used for hosts file, CA store, systemd.
# Usage: ./setup-coding-proxy-linux.sh [sk-...]
set -euo pipefail

PROXY_HOST=coding-proxy.nautilus-tooling01.live.ix01.sipgate.net
CA_NAME=sipgate-ca-root_2018-06-01.crt
MAC=sipgatejj@100.88.82.118 # mac, tailscale IP
KEY=/root/.ssh/id_ed25519_mac_forward
API_KEY="${1:-}"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CA="$script_dir/$CA_NAME"
if [ ! -f "$CA" ]; then
	echo "CA not found: $CA (copy .setup/ai/ from the mac first)" >&2
	exit 1
fi

# CA for NODE_EXTRA_CA_CERTS (node/pi ignores the system store)
mkdir -p "$HOME/.pi/certs"
cp -f "$CA" "$HOME/.pi/certs/"

# system trust store (curl/git/openssl)
if command -v update-ca-certificates >/dev/null; then
	sudo cp -f "$CA" "/usr/local/share/ca-certificates/$CA_NAME"
	sudo update-ca-certificates
elif command -v update-ca-trust >/dev/null; then
	if [ -d /etc/pki/ca-trust/source/anchors ]; then
		anchor=/etc/pki/ca-trust/source/anchors # fedora/rhel
	else
		anchor=/etc/ca-certificates/trust-source/anchors # arch
	fi
	sudo cp -f "$CA" "$anchor/$CA_NAME"
	sudo update-ca-trust
else
	echo "no CA update tool found (update-ca-certificates / update-ca-trust)" >&2
	exit 1
fi

# 127.0.0.1 -> proxy hostname; TLS SNI stays correct, traffic flows through the tunnel
if ! grep -qF "$PROXY_HOST" /etc/hosts; then
	echo "127.0.0.1 $PROXY_HOST" | sudo tee -a /etc/hosts >/dev/null
fi

# env vars for pi + update-sipgate-models
if [ -n "$API_KEY" ]; then
	KEY_VALUE="$API_KEY"
elif [ -n "${SIPGATE_CODING_PROXY_KEY:-}" ]; then
	KEY_VALUE="$SIPGATE_CODING_PROXY_KEY"
else
	KEY_VALUE=""
	echo "warning: SIPGATE_CODING_PROXY_KEY not written; re-run with the key as" \
		"argument (key lives in ~/.config/fish/conf.d/ai.fish on the mac)" >&2
fi

if [ "${SHELL##*/}" = fish ]; then
	conf="$HOME/.config/fish/conf.d/sipgate-coding-proxy.fish"
	mkdir -p "$(dirname "$conf")"
	{
		echo "set -gx NODE_EXTRA_CA_CERTS \$HOME/.pi/certs/$CA_NAME"
		if [ -n "$KEY_VALUE" ]; then
			echo "set -gx SIPGATE_CODING_PROXY_KEY \"$KEY_VALUE\""
		else
			echo "# set -gx SIPGATE_CODING_PROXY_KEY sk-..."
		fi
	} > "$conf"
else
	case "${SHELL##*/}" in
		zsh) rc=$HOME/.zshrc ;;
		bash) rc=$HOME/.bashrc ;;
		*) rc=$HOME/.zshrc ;;
	esac
	touch "$rc"
	sed -i '/^# >>> sipgate coding proxy >>>$/,/^# <<< sipgate coding proxy <<<$/d' "$rc"
	{
		echo "# >>> sipgate coding proxy >>>"
		echo "export NODE_EXTRA_CA_CERTS=\"\$HOME/.pi/certs/$CA_NAME\""
		if [ -n "$KEY_VALUE" ]; then
			echo "export SIPGATE_CODING_PROXY_KEY=\"$KEY_VALUE\""
		fi
		echo "# <<< sipgate coding proxy <<<"
	} >> "$rc"
fi

# ssh key for the tunnel service (root, referenced by the unit below)
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh
if ! sudo test -f "$KEY"; then
	sudo ssh-keygen -t ed25519 -N '' -f "$KEY" -C "coding-proxy-tunnel@$(hostname)"
fi

# root service: binds 443, autostarts at boot, reconnects when the mac is back
sudo tee /etc/systemd/system/coding-proxy-tunnel.service >/dev/null <<EOF
[Unit]
Description=sipgate coding proxy tunnel (ssh -L via mac over tailscale)
Wants=network-online.target
After=network-online.target tailscaled.service
StartLimitIntervalSec=0

[Service]
ExecStart=/usr/bin/ssh -N -L 127.0.0.1:443:$PROXY_HOST:443 -i $KEY \\
	-o BatchMode=yes -o StrictHostKeyChecking=accept-new \\
	-o ServerAliveInterval=15 -o ServerAliveCountMax=3 \\
	-o ExitOnForwardFailure=yes \\
	$MAC
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now coding-proxy-tunnel.service

echo
echo "next steps:"
echo "  1. authorize the tunnel key on the mac (asks for the mac login password):"
echo "       sudo ssh-copy-id -i $KEY.pub $MAC"
echo "     the service keeps retrying until this is done"
echo "  2. open a new shell (for NODE_EXTRA_CA_CERTS / SIPGATE_CODING_PROXY_KEY), then test:"
echo "       curl -fsS https://$PROXY_HOST/v1/models -H \"Authorization: Bearer \$SIPGATE_CODING_PROXY_KEY\" | head -c 200"
echo "  3. logs: journalctl -u coding-proxy-tunnel -f"
