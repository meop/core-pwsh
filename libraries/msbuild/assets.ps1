function Get-MSBuildProjectsMap {
    Import-AssetCsv `
        -Path "$(Get-ProfileAssetsDir)/msbuild/projects.map.csv"
}

function Get-MsBuildProjectsBatchFilePaths (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
) {
    Get-AssetBatchFilePaths `
        -Path "$(Get-ProfileAssetsDir)/msbuild/projects.txt" `
        -Filters $Filters `
        -UnionFilters:$UnionFilters
}

function Get-MsBuildProjectsGroupFilePaths (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
) {
    Get-AssetGroupFilePaths `
        -Path "$(Get-ProfileAssetsDir)/msbuild/project-groups/$GroupName" `
        -StartName $StartName `
        -StopName $StopName
}

function Update-MsBuildProjectsCacheFile (
    [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Update-AssetCacheFile `
        -Include '*.sln' `
        -SearchPaths $Config['msBuild']['searchPaths'] `
        -OutFilePath "$(Get-ProfileAssetsDir)/msbuild/projects.txt"
}