function Get-ProfileConfig {
    Write-Debug "called: Get-ProfileConfig"
    $p = "$global:PROFILE_ASSETS_DIR/config.yml"

    (Test-Path $p) ? (ConvertFrom-Yaml (Get-Content -Raw $p)) : $null
}