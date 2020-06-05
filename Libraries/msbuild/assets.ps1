function Get-MSBuildProjectsMap {
    Import-AssetCsv `
        -Path "$global:PROFILE_ASSETS_DIR/msbuild/projects.map.csv"
}

function Get-MsBuildProjectsBatchFilePaths (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
) {
    Get-AssetBatchFilePaths `
        -Path "$global:PROFILE_ASSETS_DIR/msbuild/projects.txt" `
        -Filters $Filters `
        -UnionFilters:$UnionFilters
}

function Get-MsBuildProjectsGroupFilePaths (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
) {
    Get-AssetGroupFilePaths `
        -Path "$global:PROFILE_ASSETS_DIR/msbuild/project-groups/$GroupName" `
        -StartName $StartName `
        -StopName $StopName
}

function Update-MsBuildProjectsCacheFile (
    [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Update-AssetCacheFile `
        -Include '*.sln' `
        -SearchPaths $Config['msBuild']['searchPaths'] `
        -OutFilePath "$global:PROFILE_ASSETS_DIR/msbuild/projects.txt"
}