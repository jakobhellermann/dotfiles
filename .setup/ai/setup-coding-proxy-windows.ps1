# One-time setup for the coding-proxy tunnel client on Windows.
# Needs an elevated shell (hosts file + machine cert store).
param([string]$ApiKey)

$ErrorActionPreference = "Stop"
$ca = Join-Path $PSScriptRoot "sipgate-ca-root_2018-06-01.crt"
$proxyHost = "coding-proxy.nautilus-tooling01.live.ix01.sipgate.net"

if (-not (Test-Path $ca)) { throw "CA not found: $ca" }

# CA file for NODE_EXTRA_CA_CERTS (node/pi ignores the machine store)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.pi\certs" | Out-Null
Copy-Item -Force $ca "$env:USERPROFILE\.pi\certs\"

# machine trust store (curl.exe/git use Schannel)
certutil -addstore -f ROOT $ca

# 127.0.0.1 -> proxy hostname; traffic then flows through the ssh tunnel
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (-not (Select-String -Path $hosts -Pattern ([regex]::Escape($proxyHost)) -Quiet)) {
	Add-Content $hosts "127.0.0.1 $proxyHost"
}

setx NODE_EXTRA_CA_CERTS "$env:USERPROFILE\.pi\certs\sipgate-ca-root_2018-06-01.crt" | Out-Null
if ($ApiKey) {
	setx SIPGATE_CODING_PROXY_KEY $ApiKey | Out-Null
}
elseif (-not $env:SIPGATE_CODING_PROXY_KEY) {
	Write-Warning "SIPGATE_CODING_PROXY_KEY not set; run: setx SIPGATE_CODING_PROXY_KEY <key from ~/.config/fish/conf.d/ai.fish on the mac>"
}
