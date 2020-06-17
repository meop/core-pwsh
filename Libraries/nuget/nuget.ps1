function Get-NugetRestoreLine (
    [Parameter(Mandatory = $true)] [string] $Project
    , [Parameter(Mandatory = $true)] [VsToolFilePaths] $VsToolFilePaths
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $msBuildPath =
    if ((Invoke-SafeCheckCommandPathEqual 'msbuild' $VsToolFilePaths.MsBuild)) {
        (Get-Command 'msbuild').Source
    } else {
        $VsToolFilePaths.MsBuild
    }

    $line = (-not (Test-Path $Project) -and -not $WhatIf.IsPresent) `
        ? "Write-Output 'skipping - project not found: $Project'" `
        : "nuget restore `"$Project`" -MSBuildPath `"$(Split-Path $msBuildPath)`""

    $line
}

function Invoke-NugetRestoreConcurrent (
    [Parameter(Mandatory = $false)] [string[]] $ProjectArray
    , [Parameter(Mandatory = $true)] [VsToolFilePaths[]] $VsToolFilePathsArray
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $ProjectArray) { return }

    $commands = @()

    for ($i = 0; $i -lt $ProjectArray.Length; ++$i) {
        $commands += Get-ConsoleCommand `
            -Line (Get-NugetRestoreLine `
                -Project $ProjectArray[$i] `
                -VsToolFilePaths $VsToolFilePathsArray[$i] `
                -WhatIf:$WhatIf `
                -Config $Config) `
            -Config $Config
    }

    $activity = 'Nuget restore'
    Invoke-CommandsConcurrent `
        -Commands $commands `
        -Activity $activity `
        -WhatIf:$WhatIf
}