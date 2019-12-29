$global:DEV_SCRIPTS_PROFILE='example'
$global:DEV_SCRIPTS_PROFILE_DIR='d:/dev-scripts'

Invoke-SafeInstallModule powershell-yaml

$f = "$($global:DEV_SCRIPTS_PROFILE_DIR)/source.ps1"
if (Test-Path $f) { . $f }

function Get-ProfileAssetsDir {
    "$global:DEV_SCRIPTS_PROFILE_DIR/assets/$global:DEV_SCRIPTS_PROFILE"
}