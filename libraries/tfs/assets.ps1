function Get-TfsReposBatchFilePaths (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
) {
    Get-AssetBatchFilePaths `
        -Path "$global:PROFILE_ASSETS_DIR/tfs/repos.txt" `
        -Filters $Filters `
        -UnionFilters:$UnionFilters
}