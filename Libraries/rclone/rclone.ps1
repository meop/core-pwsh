Import-Module File

enum RCloneOperation {
    copyto
    sync
}

function Get-RCloneCommand (
    [Parameter(Mandatory = $true)] [RCloneOperation] $Operation
    , [Parameter(Mandatory = $true)] [string] $Origination
    , [Parameter(Mandatory = $true)] [string] $Destination
    , [Parameter(Mandatory = $false)] [string] $Flags
    , [Parameter(Mandatory = $false)] [switch] $AsSudo
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $line = "rclone $Operation $Origination $Destination"
    if ($Flags) { $line += " $Flags" }

    if ($AsSudo.IsPresent) {
        $line = Format-AsSudo $line
    }

    Get-ConsoleCommand `
        -Line $line `
        -Config $Config
}

function Invoke-RCloneGroup (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $SourceName
    , [Parameter(Mandatory = $false)] [string] $RemoteName
    , [Parameter(Mandatory = $false)] [string] $Filter
    , [Parameter(Mandatory = $false)] [switch] $Restore
    , [Parameter(Mandatory = $false)] [switch] $CopyLinks
    , [Parameter(Mandatory = $false)] [switch] $DryRun
    , [Parameter(Mandatory = $false)] [switch] $AsSudo
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $backupGroup = Get-RCloneBackupGroup $GroupName $Filter
    if (-not $backupGroup) {
        $f = $Filter ? ", filter: $Filter" : ''
        Write-Output "no backup group found for group name: $GroupName$f"
        return
    }

    $backupGroupRemotes = Get-RCloneBackupGroupRemotes $GroupName
    if (-not $backupGroupRemotes) {
        Write-Output "no backup group remotes found for group name: $GroupName"
        return
    }

    foreach ($backupGroupRemote in $backupGroupRemotes) {
        $source = $backupGroupRemote.Source
        $remote = $backupGroupRemote.Remote

        if ($SourceName -and $SourceName -ne $source) {
            continue
        }

        if ($RemoteName -and $RemoteName -ne $remote) {
            continue
        }

        $commands = @()

        foreach ($backup in $backupGroup) {
            $path =
                $ExecutionContext.InvokeCommand.ExpandString(
                    $backup.Path
                )

            $flags = ''
            if ($CopyLinks.IsPresent) { $flags += ' --copy-links' }
            if ($DryRun.IsPresent) { $flags += ' --dry-run' }

            $localPath = ConvertTo-CrossPlatformPathFormat $path

            $origination = "$($source):`"$localPath`""

            $remotePathPrefix = ConvertTo-CrossPlatformPathFormat `
                $ExecutionContext.InvokeCommand.ExpandString(
                    $backupGroupRemote.RemotePath
                )

            $remotePathPostfix = ConvertTo-ExpandedDirectoryPathFormat `
                $ExecutionContext.InvokeCommand.ExpandString(
                    $($backup.NewPath ? $backup.NewPath : $path)
                )

            $remotePath = "$remotePathPrefix/$(Edit-TrimForwardSlashes $remotePathPostfix)"

            $destination = "$($remote):`"$remotePath`""

            if ($Restore.IsPresent) {
                $p = $origination
                $origination = $destination
                $destination = $p
            }

            $commands += Get-RCloneCommand `
                -Operation $backup.Operation `
                -Origination $origination `
                -Destination $destination `
                -Flags $flags `
                -AsSudo:$AsSudo `
                -Config $Config
        }

        Invoke-CommandsConcurrent `
            -Commands $commands `
            -WhatIf:$WhatIf
    }
}