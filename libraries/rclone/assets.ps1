function Get-RCloneBackupGroupRemote (
    [Parameter(Mandatory = $true)] [string] $GroupName
) {
    $groupName = $GroupName.ToLowerInvariant()

    Import-AssetCsv `
        -Path "$(Get-ProfileAssetsDir)/rclone/backups.csv" |
    Where-Object { $groupName -eq $_.Group.ToLowerInvariant() } |
    Select-Object -First 1
}

function Get-RCloneBackupGroup (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $Filter
) {
    $groupName = $GroupName.ToLowerInvariant()

    $x = Import-AssetCsv `
        -Path "$(Get-ProfileAssetsDir)/rclone/backup-groups/$groupName"

    if ($Filter) {
        $filter = $Filter.ToLowerInvariant()
        $x | Where-Object {
            $_.Path.ToLowerInvariant().Contains($filter) -or
            $_.NewPath.ToLowerInvariant().Contains($filter)
        }
    } else {
        $x
    }
}