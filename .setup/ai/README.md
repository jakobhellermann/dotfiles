# coding proxy access from outside the VPN

pi on a machine without VPN reaches the sipgate coding proxy through an ssh
tunnel via a machine that IS in the VPN (the mac):

```
windows/linux (pi/curl) -> 127.0.0.1:443 -> ssh -L -> mac (sshd) -> OpenVPN -> coding.sipgate.ai
```

tailscale subnet routing through the mac does NOT work (the tailscale network
extension can't egress through the OpenVPN tunnel), hence the ssh tunnel.

`coding.sipgate.ai` is the canonical proxy URL but only reachable from inside
the VPN: the IP resolves publicly but is firewalled from outside. The tunnel is
what makes it work from the windows/linux machines.

## provider: pi extension sipgate-proxy.ts

The `sipgate` provider is NOT a static models.json — it is registered by
`~/.pi/agent/extensions/sipgate-proxy.ts` (tracked in the dotfiles):

- baseUrl `https://coding.sipgate.ai`, api key from `$SIPGATE_CODING_PROXY_KEY`
- models are auto-discovered from the proxy (`/models` + `/model/info`,
  LiteLLM-style) and cached in `~/.pi/agent/models-store.json`
- first pi start bootstraps the catalog through the tunnel; `/sipgate-refresh`
  re-runs the discovery manually
- works offline from the cached snapshot (no network at pi startup)

Linux still runs the OLD setup (static models.json with
coding-proxy.nautilus-tooling01.live.ix01.sipgate.net as baseUrl) — it has no
hosts entry for coding.sipgate.ai. Migrating it to the extension means:
hosts entry + tunnel service target → coding.sipgate.ai, remove models.json.

## windows (one-time, elevated powershell)

```powershell
.\setup-coding-proxy-windows.ps1 [-ApiKey sk-...]
```

hosts entry, CA into machine store + `%USERPROFILE%\.pi\certs`, user env vars.
`.pi` (settings.json, extensions/) syncs via the dotfiles repo.

the tunnel is one manual command in a terminal — run it ON the windows
machine (the mac cannot resolve `*.ts.net`, its tailscale variant sets no
resolver for it; from the mac: `ssh jakob@100.71.131.126` first). Keep the
window open, closing it stops the tunnel:

```powershell
ssh -N -L 127.0.0.1:443:coding.sipgate.ai:443 -o ExitOnForwardFailure=yes sipgatejj@sipgatejj.tail335875.ts.net
```

(the mac's tailscale MagicDNS name instead of its 100.x IP; the short form
`sipgatejj` does not resolve on windows — single-label names go through
LLMNR/NetBIOS, not the DNS resolver)

uses `%USERPROFILE%\.ssh\id_ed25519` (default identity), authorized in the
mac's `~/.ssh/authorized_keys`; the mac's host key is accepted once on first
connect.

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

`.pi` syncs via the dotfiles repo, same as windows.

## mac (gateway)

needs nothing beyond sshd (Remote Login) and the VPN: both tunnels are pulled
by the clients, the mac resolves coding.sipgate.ai through the OpenVPN route.
Only works while the mac is on and connected to the VPN.

## notes

- `curl` on windows needs `--ssl-no-revoke` (the internal CA's CRL/OCSP is
  unreachable from outside); linux curl and node/pi do no revocation checking
- models refresh: `/sipgate-refresh` in pi (extension machines); on linux
  (static models.json) run `update-sipgate-models` (needs
  `SIPGATE_CODING_PROXY_KEY`)
- the proxy serves both names, old and new, with certs from the same internal
  CA chain; the old name (coding-proxy.nautilus-tooling01...) keeps working
