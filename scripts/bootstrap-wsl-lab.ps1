[CmdletBinding()]
param(
    [string]$BaseDistribution = "Ubuntu",
    [string]$LabRoot = (Join-Path $env:LOCALAPPDATA "DevSecOpsLab")
)

$ErrorActionPreference = "Stop"
$nodes = @(
    @{ Name = "linux-control"; Port = 2221 },
    @{ Name = "linux-node1"; Port = 2222 },
    @{ Name = "linux-node2"; Port = 2223 }
)

function Get-WslRows {
    $lines = (& wsl.exe --list --verbose) -replace "`0", ""
    return $lines | Select-Object -Skip 1 | Where-Object { $_.Trim() }
}

function Test-WslDistribution([string]$Name) {
    return [bool](Get-WslRows | Where-Object { $_ -match "^\s*\*?\s*$([regex]::Escape($Name))\s+" })
}

function Assert-Wsl2([string]$Name) {
    $row = Get-WslRows | Where-Object { $_ -match "^\s*\*?\s*$([regex]::Escape($Name))\s+" } | Select-Object -First 1
    if (-not $row) {
        throw "WSL distribution '$Name' is not installed."
    }
    if ($row -notmatch "\s2\s*$") {
        throw "WSL distribution '$Name' must use WSL2. Restart Windows, then run: wsl --set-version $Name 2"
    }
}

function Invoke-WslRoot([string]$Distribution, [string]$Command) {
    & wsl.exe -d $Distribution -u root -- bash -lc $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed in '$Distribution' with exit code $LASTEXITCODE."
    }
}

Assert-Wsl2 $BaseDistribution
New-Item -ItemType Directory -Force -Path $LabRoot | Out-Null
$exportPath = Join-Path $LabRoot "$BaseDistribution.tar"

if ($nodes | Where-Object { -not (Test-WslDistribution $_.Name) }) {
    Write-Host "Exporting $BaseDistribution as a reusable lab image..."
    & wsl.exe --export $BaseDistribution $exportPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to export '$BaseDistribution'." }
}

foreach ($node in $nodes) {
    $name = $node.Name
    $port = $node.Port
    if (-not (Test-WslDistribution $name)) {
        $installPath = Join-Path $LabRoot $name
        New-Item -ItemType Directory -Force -Path $installPath | Out-Null
        & wsl.exe --import $name $installPath $exportPath --version 2
        if ($LASTEXITCODE -ne 0) { throw "Failed to import '$name'." }
    }

    $setup = @"
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openssh-server sudo
id devsecops >/dev/null 2>&1 || useradd --create-home --shell /bin/bash devsecops
install -d -m 0700 -o devsecops -g devsecops /home/devsecops/.ssh
printf 'devsecops ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/devsecops
chmod 0440 /etc/sudoers.d/devsecops
cat >/etc/wsl.conf <<'EOF'
[boot]
systemd=true
[user]
default=devsecops
EOF
cat >/etc/ssh/sshd_config.d/60-devsecops-lab.conf <<'EOF'
Port $port
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF
"@
    Invoke-WslRoot $name $setup
}

Invoke-WslRoot "linux-control" @'
set -euo pipefail
test -f /home/devsecops/.ssh/id_ed25519 || sudo -u devsecops ssh-keygen -q -t ed25519 -N '' -f /home/devsecops/.ssh/id_ed25519
'@

$publicKey = (& wsl.exe -d linux-control -u devsecops -- cat /home/devsecops/.ssh/id_ed25519.pub) -replace "`0", ""
if ($LASTEXITCODE -ne 0 -or -not $publicKey.Trim()) { throw "Failed to read the control-node public key." }
$publicKey = $publicKey.Trim()
if ($publicKey -notmatch '^ssh-ed25519 [A-Za-z0-9+/=]+(?: .*)?$') {
    throw "The control-node public key has an unexpected format."
}

foreach ($name in @("linux-node1", "linux-node2")) {
    Invoke-WslRoot $name "printf '%s\n' '$publicKey' >/home/devsecops/.ssh/authorized_keys; chown devsecops:devsecops /home/devsecops/.ssh/authorized_keys; chmod 0600 /home/devsecops/.ssh/authorized_keys"
}

& wsl.exe --shutdown
foreach ($node in $nodes) {
    & wsl.exe -d $node.Name -- true
}
Start-Sleep -Seconds 5

$inventoryDirectory = Join-Path $PSScriptRoot "..\inventory\generated"
New-Item -ItemType Directory -Force -Path $inventoryDirectory | Out-Null
$inventoryPath = Join-Path $inventoryDirectory "hosts.yml"
@"
all:
  vars:
    ansible_user: devsecops
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
    ansible_python_interpreter: /usr/bin/python3
  hosts:
    linux-node1:
      ansible_host: 127.0.0.1
      ansible_port: 2222
    linux-node2:
      ansible_host: 127.0.0.1
      ansible_port: 2223
"@ | Set-Content -Encoding utf8 $inventoryPath

if (Test-Path $exportPath) {
    Remove-Item -Force $exportPath
}
Write-Host "Lab ready. Inventory: $inventoryPath"
Write-Host "Validate from linux-control after copying the generated inventory: ansible all -m ping"
