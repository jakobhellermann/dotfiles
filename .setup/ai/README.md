# coding proxy access from outside the VPN

pi on a machine without VPN reaches the sipgate coding proxy through an ssh
tunnel via a machine that IS in the VPN (the mac):

```
windows (pi/curl) -> 127.0.0.1:443 -> ssh -R tunnel -> mac -> OpenVPN -> coding-proxy
```

tailscale subnet routing through the mac does NOT work (the tailscale network
extension can't egress through the OpenVPN tunnel), hence the ssh tunnel.

## windows (one-time, elevated powershell)

```powershell
.\setup-coding-proxy-windows.ps1 [-ApiKey sk-...]
```

hosts entry, CA into machine store + `%USERPROFILE%\.pi\certs`, user env vars.
`.pi` (models.json, settings.json, SYSTEM.md, skills) is copied manually from
the mac, not tracked.

## linux: linux pulls the tunnel (one-time, on the linux machine)

```
linux (pi/curl) -> 127.0.0.1:443 -> ssh -L -> mac (sshd) -> OpenVPN -> coding-proxy
```

No sshd on the linux machine; a root systemd service binds 443, autostarts at
boot and reconnects when the mac is back:

```sh
./setup-coding-proxy-linux.sh [sk-...]   # hosts entry, CA, env vars, service
sudo ssh-copy-id -i /root/.ssh/id_ed25519_mac_forward.pub sipgatejj@100.88.82.118
journalctl -u coding-proxy-tunnel -f     # tunnel logs
```

`.pi` is copied manually from the mac, same as windows.

## mac (gateway)

windows tunnel, manual, no autostart:

```sh
.setup/ai/coding-proxy-tunnel.sh   # Ctrl-C stops
```

Needs `~/.ssh/id_ed25519_win_forward`, authorized in
`C:\ProgramData\ssh\administrators_authorized_keys` on the windows machine.
The linux tunnel needs nothing on the mac beyond sshd (Remote Login) and its
key in `~/.ssh/authorized_keys`. Only works while the mac is on and connected
to the VPN.

## notes

- `curl` on windows needs `--ssl-no-revoke` (the internal CA's CRL/OCSP is
  unreachable from outside); linux curl and node/pi do no revocation checking
- models refresh: run `update-sipgate-models` (needs `SIPGATE_CODING_PROXY_KEY`)
