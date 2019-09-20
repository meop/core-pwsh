if ($PSEdition -ne 'Core') {
    Write-Output 'Please install and use PS Core: https://github.com/PowerShell/PowerShell'
    Write-Output 'You are using:'
    Write-Output $PSVersionTable
    exit
}

function Invoke-SafeAppendToModulePath ($p) {
    $splitter = if ($IsWindows) { ';' } else { ':' }
    if (Test-Path $p) {
        $env:PSModulePath += "$splitter$p"
    }
}

Invoke-SafeAppendToModulePath "$PSScriptRoot/modules"

$f = "$PSScriptRoot/assets.ps1"
if (Test-Path $f) { . $f }

$d = "$PSScriptRoot/libraries"
if (Test-Path $d) {
    Get-ChildItem -Path $d -Filter '*.ps1' -Recurse -Depth 1 |
    ForEach-Object { . $_.FullName }
}

$f = "$PSScriptRoot/aliases.ps1"
if (Test-Path $f) { . $f }
