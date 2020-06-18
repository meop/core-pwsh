function Get-ProfileConfig {
    Write-Debug "called: Get-ProfileConfig"

    $config = "$PSScriptRoot/config.yml"
    (Test-Path $config) ? (ConvertFrom-Yaml (Get-Content -Raw $config)) : $null
}

# need this for parsing config
Invoke-SafeInstallModule powershell-yaml
