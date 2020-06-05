function Get-GitTfsCloneCommand (
    [Parameter(Mandatory = $true)] [string] $Trunk
    , [Parameter(Mandatory = $false)] [switch] $FullClone
    , [Parameter(Mandatory = $false)] [string] $IgnoreRegex
    , [Parameter(Mandatory = $false)] [int] $ChangeSet
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $uri = $Config['tfs']['uri']
    $cloneDir = ConvertTo-CrossPlatformPathFormat "$($Config['gitTfs']['cloneDir'])/$Trunk"
    $workspaceDir = ConvertTo-CrossPlatformPathFormat "$($Config['gitTfs']['workspaceDir'])/$Trunk"

    $line =
    if ((Test-Path $cloneDir) -and -not $WhatIf.IsPresent) {
        "Write-Output 'skipping - directory already found: $cloneDir'"
    } else {
        $operation = $FullClone.IsPresent ? "clone" : "quick-clone"
        $_changeset = $ChangeSet ? "--changeset=$ChangeSet" : ""
        $_ignoreregex = $IgnoreRegex ? "--ignore-regex=$IgnoreRegex" : ""

        "git tfs $operation $uri $/$Trunk $cloneDir --branches=none $_changeset $_ignoreregex --workspace=$workspaceDir"
    }

    Get-ConsoleCommand `
        -Line $line `
        -Config $Config
}

function Invoke-GitTfsCloneConcurrent (
    [Parameter(Mandatory = $false)] [string[]] $Trunks
    , [Parameter(Mandatory = $false)] [switch] $FullClone
    , [Parameter(Mandatory = $false)] [string] $IgnoreRegex
    , [Parameter(Mandatory = $false)] [int] $ChangeSet
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Trunks) { return }

    $commands = @()

    foreach ($trunk in $Trunks) {
        $commands += Get-GitTfsCloneCommand `
            -Trunk $trunk `
            -FullClone:$FullClone `
            -IgnoreRegex $IgnoreRegex `
            -ChangeSet $ChangeSet `
            -WhatIf:$WhatIf `
            -Config $Config
    }

    Invoke-CommandsConcurrent `
        -Commands $commands `
        -WhatIf:$WhatIf
}

function Invoke-GitTfsCloneBatch (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
    , [Parameter(Mandatory = $false)] [switch] $FullClone
    , [Parameter(Mandatory = $false)] [string] $IgnoreRegex
    , [Parameter(Mandatory = $false)] [int] $ChangeSet
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-GitTfsCloneConcurrent `
        -Trunks (
            Get-TfsReposBatchFilePaths `
                -Filters $Filters `
                -UnionFilters:$UnionFilters
        ) `
        -FullClone:$FullClone `
        -IgnoreRegex $IgnoreRegex `
        -ChangeSet $ChangeSet `
        -WhatIf:$WhatIf `
        -Config $Config
}

function Get-GitTfsFetchCommand (
    [Parameter(Mandatory = $true)] [string] $Repo
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $line = (-not (Test-Path $Repo) -and -not $WhatIf.IsPresent) `
        ? "Write-Output 'skipping - repo not found: $Repo; did you clone yet?'" `
        : "git tfs fetch"

    Get-ConsoleCommand `
        -Line $line `
        -WorkingDir $Repo `
        -Config $Config
}

function Invoke-GitTfsFetchConcurrent (
    [Parameter(Mandatory = $false)] [string[]] $Repos
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Repos) { return }

    $commands = @()

    foreach ($repo in $Repos) {
        $commands += Get-GitTfsFetchCommand `
            -Repo $repo `
            -WhatIf:$WhatIf `
            -Config $Config
    }

    Invoke-CommandsConcurrent `
        -Commands $commands `
        -WhatIf:$WhatIf
}

function Invoke-GitTfsFetchBatch (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-GitTfsFetchConcurrent `
        -Repos (
            Get-GitReposBatchFilePaths `
                -Filters $Filters `
                -UnionFilters:$UnionFilters
        ) `
        -WhatIf:$WhatIf `
        -Config $Config
}

function Invoke-GitTfsFetchGroup (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-GitTfsFetchConcurrent `
        -Repos (
            Get-GitReposGroupFilePaths `
                -GroupName $GroupName `
                -StartName $StartName `
                -StopName $StopName
        ) `
        -WhatIf:$WhatIf `
        -Config $Config
}