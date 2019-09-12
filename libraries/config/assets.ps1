function Get-ProfileConfig {
    Write-Debug "called: Get-ProfileConfig"
    ConvertFrom-Yaml (Get-Content -Raw "$(Get-ProfileAssetsDir)/config.yml")
}