enum RcloneOperation {
    copyto
    sync
}

function Get-RcloneCommand (
    [Parameter(Mandatory = $true)] [RcloneOperation] $Operation
    , [Parameter(Mandatory = $true)] [string] $Source
    , [Parameter(Mandatory = $true)] [string] $Destination
    , [Parameter(Mandatory = $false)] [string] $Flags
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $line = "rclone $Operation $Source $Destination"
    if ($Flags) { $line += " $Flags" }

    Get-ConsoleCommand `
        -Line $line `
        -Config $Config
}

function Invoke-RcloneGroup (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $Filter
    , [Parameter(Mandatory = $false)] [switch] $Restore
    , [Parameter(Mandatory = $false)] [switch] $CopyLinks
    , [Parameter(Mandatory = $false)] [switch] $DryRun
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $backupGroup = Get-RcloneBackupGroup $GroupName $Filter
    if (-not $backupGroup) {
        $f = if ($Filter) { ", filter: $Filter" } else { '' }
        Write-Output "no backup group found for group name: $GroupName$f"
        return
    }

    $backupGroupRemote = Get-RcloneBackupGroupRemote $GroupName
    if (-not $backupGroupRemote) {
        Write-Output "no backup group remote found for group name: $GroupName"
        return
    }

    $remote = $backupGroupRemote.Remote

    $commands = @()

    foreach ($backup in $backupGroup) {
        $path = $ExecutionContext.InvokeCommand.ExpandString($backup.Path)

        $flags = ''
        if ($CopyLinks.IsPresent) { $flags += ' --copy-links' }
        if ($DryRun.IsPresent) { $flags += ' --dry-run' }

        $localPath = ConvertTo-CrossPlatformPathFormat $path

        $source = "$($Config['rclone']['remote']):'$localPath'"

        $remotePathPrefix = ConvertTo-CrossPlatformPathFormat `
            $ExecutionContext.InvokeCommand.ExpandString(
            $backupGroupRemote.RemotePath
        )

        $remotePathPostfix = ConvertTo-ExpandedDirectoryPathFormat `
            $ExecutionContext.InvokeCommand.ExpandString($(
                if ($backup.NewPath) { $backup.NewPath }
                else { $path }
            ))

        $remotePath = "$remotePathPrefix/$(Edit-TrimForwardSlashes $remotePathPostfix)"

        $destination = "$($remote):'$remotePath'"

        if ($Restore.IsPresent) {
            $p = $source
            $source = $destination
            $destination = $p
        }

        $pathToCheck = if ($Restore.IsPresent) { $remotePath } else { $localPath }

        $commands +=
        if (-not (Test-Path $pathToCheck)) {
            Get-ConsoleCommand `
                -Line "Write-Output 'skipping - invalid path: $pathToCheck'" `
                -Config $Config
        } else {
            Get-RcloneCommand `
                -Operation (
                    if (Test-PathIsOfType $pathToCheck Leaf) {
                        [RcloneOperation]::copyto
                    } else {
                        [RcloneOperation]::sync
                    }
                ) `
                -Source $source `
                -Destination $destination `
                -Flags $flags `
                -Config $Config
        }
    }

    Invoke-CommandsConcurrent `
        -Commands $commands `
        -WhatIf:$WhatIf
}