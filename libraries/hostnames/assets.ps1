function Get-Hostnames {
    ConvertFrom-Yaml (Get-Content -Raw "$(Get-ProfileAssetsDir)/hostnames.yml")
}