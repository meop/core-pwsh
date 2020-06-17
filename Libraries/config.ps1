function Get-ProfileConfig {
    Write-Debug "called: Get-ProfileConfig"
    $p = "$PSScriptRoot/../config.yml"

    (Test-Path $p) ? (ConvertFrom-Yaml (Get-Content -Raw $p)) : $null
}

# need this for parsing config
Invoke-SafeInstallModule powershell-yaml
