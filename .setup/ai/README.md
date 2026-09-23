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

Linux uses the extension as well: hosts entry + user tunnel service point at
coding.sipgate.ai, no static models.json.

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


## mac (gateway)

needs nothing beyond sshd (Remote Login) and the VPN: both tunnels are pulled
by the clients, the mac resolves coding.sipgate.ai through the OpenVPN route.
Only works while the mac is on and connected to the VPN.

## notes

- `curl` on windows needs `--ssl-no-revoke` (the internal CA's CRL/OCSP is
  unreachable from outside); linux curl and node/pi do no revocation checking
- models refresh: `/sipgate-refresh` in pi (extension machines)
- the proxy serves both names, old and new, with certs from the same internal
  CA chain; the old name (coding-proxy.nautilus-tooling01...) keeps working
