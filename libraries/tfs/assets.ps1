function Get-TfsReposBatchFilePaths (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
) {
    Get-AssetBatchFilePaths `
        -Path "$(Get-ProfileAssetsDir)/tfs/repos.txt" `
        -Filters $Filters `
        -UnionFilters:$UnionFilters
}