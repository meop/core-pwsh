Import-Module File

enum RCloneOperation {
    copyto
    sync
}

class RCloneBackupItem {
    [RCloneOperation] $Operation
    [string] $Path
    [string] $NewPath
}

class RCloneBackup {
    [string] $Source
    [string] $Remote
    [string] $RemotePath
    [RCloneBackupItem[]] $Items
}

function Get-RCloneLine (
    [Parameter(Mandatory = $true)] [RCloneOperation] $Operation
    , [Parameter(Mandatory = $true)] [string] $Origination
    , [Parameter(Mandatory = $true)] [string] $Destination
    , [Parameter(Mandatory = $false)] [string] $Flags
    , [Parameter(Mandatory = $false)] [switch] $AsSudo
) {
    $line = "rclone $Operation $Origination $Destination"
    if ($Flags) { $line += " $Flags" }

    if ($AsSudo.IsPresent) {
        $line = Format-AsSudo $line
    }

    $line
}

function Invoke-RCloneBackup (
    [Parameter(Mandatory = $true)] [RCloneBackup] $Backup
    , [Parameter(Mandatory = $false)] [string] $Filter
    , [Parameter(Mandatory = $false)] [switch] $Restore
    , [Parameter(Mandatory = $false)] [switch] $CopyLinks
    , [Parameter(Mandatory = $false)] [switch] $DryRun
    , [Parameter(Mandatory = $false)] [switch] $AsSudo
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Backup.Items) { return }

    $items =
    if ($Filter) {
        $filter = $Filter.ToLowerInvariant()
        function isInFilter ([string] $s) {
            $s -and $s.Contains($filter)
        }

        $backup.Items | Where-Object {
            (isInFilter $_.Path) -or
            (isInFilter $_.NewPath)
        }
    } else {
        $backup.Items
    }


    $commands = @()

    foreach ($item in $items) {
        $path =
            $ExecutionContext.InvokeCommand.ExpandString(
                $item.Path
            )

        $flags = ''
        if ($CopyLinks.IsPresent) { $flags += ' --copy-links' }
        if ($DryRun.IsPresent) { $flags += ' --dry-run' }

        $localPath = ConvertTo-CrossPlatformPathFormat $path

        $origination = "$($Backup.Source):`"$localPath`""

        $remotePathPrefix = ConvertTo-CrossPlatformPathFormat `
            $ExecutionContext.InvokeCommand.ExpandString(
                $Backup.RemotePath
            )

        $remotePathPostfix = ConvertTo-ExpandedDirectoryPathFormat `
            $ExecutionContext.InvokeCommand.ExpandString(
                $($item.NewPath ? $item.NewPath : $path)
            )

        $remotePath = "$remotePathPrefix/$(Edit-TrimForwardSlashes $remotePathPostfix)"

        $destination = "$($Backup.Remote):`"$remotePath`""

        if ($Restore.IsPresent) {
            $p = $origination
            $origination = $destination
            $destination = $p
        }

        $commands += Get-ConsoleCommand `
            -Line (Get-RCloneLine `
                -Operation $item.Operation `
                -Origination $origination `
                -Destination $destination `
                -Flags $flags `
                -AsSudo:$AsSudo `
                -Config $Config) `
            -Config $Config
    }

    $activity = 'RClone invoke'
    Invoke-CommandsConcurrent `
        -Commands $commands `
        -Activity $activity `
        -WhatIf:$WhatIf
}