function Get-GitTfsCloneLine (
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

    $line
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
        $commands += Get-ConsoleCommand `
            -Line (Get-GitTfsCloneLine `
                -Trunk $trunk `
                -FullClone:$FullClone `
                -IgnoreRegex $IgnoreRegex `
                -ChangeSet $ChangeSet `
                -WhatIf:$WhatIf `
                -Config $Config) `
            -Config $Config
    }

    $activity = 'Git TFS clone'
    Invoke-CommandsConcurrent `
        -Commands $commands `
        -Activity $activity `
        -WhatIf:$WhatIf
}

function Get-GitTfsFetchLine (
    [Parameter(Mandatory = $false)] [string] $Repo
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Repo) { return }

    $line = (-not (Test-Path $Repo) -and -not $WhatIf.IsPresent) `
        ? "Write-Output 'skipping - repo not found: $Repo; did you clone yet?'" `
        : "git tfs fetch"

    $line
}

function Invoke-GitTfsFetchConcurrent (
    [Parameter(Mandatory = $false)] [string[]] $Repos
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Repos) { return }

    $commands = @()

    foreach ($repo in $Repos) {
        $commands += Get-ConsoleCommand `
            -Line (Get-GitTfsFetchLine `
                -Repo $repo `
                -WhatIf:$WhatIf `
                -Config $Config) `
            -WorkingDir $Repo `
            -Config $Config
    }

    $activity = "Git TFS fetch"
    Invoke-CommandsConcurrent `
        -Commands $commands `
        -Activity $activity `
        -WhatIf:$WhatIf
}

function Invoke-GitTfsRebaseWithRetriesGroup (
    [Parameter(Mandatory = $false)] [string[]] $Paths
    , [Parameter(Mandatory = $false)] [string] $TargetBranch = 'tfs/default'
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $paths) { return }

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) { continue }

        Invoke-GitRebaseWithRetries `
            -RepoDir $path `
            -TargetBranch $TargetBranch `
            -WhatIf:$WhatIf `
            -Config $Config
    }
}