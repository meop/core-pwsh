function Get-NugetRestoreCommand (
    [Parameter(Mandatory = $true)] [string] $Project
    , [Parameter(Mandatory = $false)] [VsToolFilePaths] $VsToolFilePaths
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $VsToolFilePaths) {
        $VsToolFilePaths = Get-VsToolFilePathsProject -Project $Project -Config $Config
    }

    $msBuildPath =
    if ((Invoke-SafeCheckCommandPathEqual 'msbuild' $VsToolFilePaths.MsBuild)) {
        (Get-Command 'msbuild').Source
    } else {
        $VsToolFilePaths.MsBuild
    }

    $line =
    if (-not (Test-Path $Project) -and -not $WhatIf.IsPresent) {
        "Write-Output 'skipping - project not found: $Project'"
    } else {
        "nuget restore `"$Project`" -MSBuildPath `"$(Split-Path $msBuildPath)`""
    }

    Get-ConsoleCommand `
        -Line $line `
        -Config $Config
}

function Invoke-NugetRestoreConcurrent (
    [Parameter(Mandatory = $false)] [string[]] $Projects
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Projects) { return }

    $commands = @()

    foreach ($project in $Projects) {
        $commands += Get-NugetRestoreCommand `
            -Project $project `
            -WhatIf:$WhatIf `
            -Config $Config
    }

    Invoke-CommandsConcurrent `
        -Commands $commands `
        -WhatIf:$WhatIf
}

function Invoke-NugetRestoreBatch (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-NugetRestoreConcurrent `
        -Projects (
            Get-MsBuildProjectsBatchFilePaths `
                -Filters $Filters `
                -UnionFilters:$UnionFilters
        ) `
        -WhatIf:$WhatIf `
        -Config $Config
}

function Invoke-NugetRestoreGroup (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-NugetRestoreConcurrent `
        -Projects (
            Get-MsBuildProjectsGroupFilePaths `
                -GroupName $GroupName `
                -StartName $StartName `
                -StopName $StopName
        ) `
        -WhatIf:$WhatIf `
        -Config $Config
}