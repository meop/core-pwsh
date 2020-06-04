function Get-Hostnames {
    ConvertFrom-Yaml (Get-Content -Raw "$global:PROFILE_ASSETS_DIR/hostnames.yml")
}