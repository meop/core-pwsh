function Get-SymlinkCommand (
    [Parameter(Mandatory = $true)] $Path
    , [Parameter(Mandatory = $true)] $TargetPath
    , [Parameter(Mandatory = $false)] [switch] $AsSudo
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $line =
    if (Test-Path $TargetPath) {
        "New-Item -Force -Path '$Path' -Value '$TargetPath' -ItemType SymbolicLink | Out-Null"
    } else {
        "Write-Output 'skipping - target path does not exist: $TargetPath'"
    }

    if ($AsSudo.IsPresent) {
        $line = Format-AsSudo $line
    }

    Get-ConsoleCommand `
        -Line $line `
        -Config $Config
}

function Invoke-SymlinkGroup (
    [Parameter(Mandatory = $false)] [switch] $AsSudo
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $linkGroup = Get-SymlinkGroup

    $commands = @()

    foreach ($link in $linkGroup) {
        $path = $ExecutionContext.InvokeCommand.ExpandString($link.Path)
        $targetPath = $ExecutionContext.InvokeCommand.ExpandString($link.TargetPath)

        $commands += Get-SymlinkCommand `
            -Path $path `
            -TargetPath $targetPath `
            -AsSudo:$AsSudo `
            -WhatIf:$WhatIf `
            -Config $Config
    }

    Invoke-CommandsConcurrent `
        -Commands $commands `
        -WhatIf:$WhatIf
}