$global:DEV_SCRIPTS_PROFILE='example'
$global:DEV_SCRIPTS_PROFILE_DIR='d:/dev-scripts'

Invoke-SafeInstallModule powershell-yaml

$f = "$($global:DEV_SCRIPTS_PROFILE_DIR)/source.ps1"
if (Test-Path $f) { . $f }
