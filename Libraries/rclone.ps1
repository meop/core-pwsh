Import-Module File

enum RCloneOperation {
    copyto
    sync
}

class RCloneBackupItem {
    [RCloneOperation] $Operation
    [string] $Path
    [string] $NewPath
    [bool] $CopyLinks
    [bool] $AsSudo
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
    , [Parameter(Mandatory = $false)] [bool] $AsSudo
    , [Parameter(Mandatory = $false)] [string] $Flags
) {
    $line = "rclone $Operation $Origination $Destination"
    if ($Flags) { $line += $Flags }

    if ($AsSudo) {
        $line = Format-AsSudo $line
    }

    $line
}

function Invoke-RCloneBackup (
    [Parameter(Mandatory = $true)] [RCloneBackup] $Backup
    , [Parameter(Mandatory = $false)] [switch] $Restore
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not $Backup.Items) { return }

    $commands = @()

    foreach ($item in $Backup.Items) {
        $path =
            $ExecutionContext.InvokeCommand.ExpandString(
                $item.Path
            )

        $flags = ''
        if ($item.CopyLinks) { $flags += ' --copy-links' }

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
                -AsSudo $item.AsSudo `
                -Flags $flags) `
            -Config $Config
    }

    $activity = 'RClone invoke'
    Invoke-CommandsConcurrent `
        -Commands $commands `
        -Activity $activity `
        -WhatIf:$WhatIf
}