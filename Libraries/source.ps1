Get-ChildItem -Path $PSScriptRoot -Include '*.ps1' -Exclude 'source.ps1' -Recurse -Depth 1 |
ForEach-Object { . $_.FullName }

# need this for parsing assets
Invoke-SafeInstallModule powershell-yaml

# need to override this before calling library functions
$global:PROFILE_ASSETS_DIR = $null