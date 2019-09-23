function Invoke-Vagrant (
    [Parameter(Mandatory = $true)] [string] $Target
    , [Parameter(Mandatory = $true)] [string] $Operation
    , [Parameter(Mandatory = $false)] [string] $Options
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
) {
    $target = $Target.ToString()

    $path = "$(Get-ProfileAssetsDir)/vagrant/$target"
    if (-not (Test-Path $path)) {
        Write-Host "Target '$target' is not set up yet.."
    }

    $line = "vagrant $Operation $Options $Target"

    $command = Get-ConsoleCommand `
        -Line $line `
        -WorkingDir $path

    Invoke-CommandsConcurrent `
        -Commands $command `
        -WhatIf:$WhatIf
}