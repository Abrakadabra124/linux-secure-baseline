$ErrorActionPreference = "Stop"
$bootstrapPath = Join-Path $PSScriptRoot "bootstrap-wsl-lab.ps1"

function Assert-Rejected {
    param(
        [scriptblock]$Action,
        [string]$ExpectedMessage
    )

    try {
        & $Action
    }
    catch {
        if ($_.Exception.Message -notlike "*$ExpectedMessage*") {
            throw "Input failed for an unexpected reason: $($_.Exception.Message)"
        }
        return
    }

    throw "Unsafe bootstrap input was accepted."
}

Assert-Rejected {
    & $bootstrapPath -FallbackDnsServers @("1.1.1.1`nEOF`nid")
} "valid IPv4 address"

Assert-Rejected {
    & $bootstrapPath -BaseDistribution "../Ubuntu"
} "unsupported characters"

Write-Host "Unsafe bootstrap parameters were rejected before WSL execution."
