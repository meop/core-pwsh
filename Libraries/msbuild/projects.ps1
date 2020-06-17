function Update-MsBuildProjectsList (
    [Parameter(Mandatory = $true)] [string] $OutFilePath
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Update-AssetList `
        -Include '*.sln' `
        -SearchPaths $Config['msBuild']['searchPaths'] `
        -OutFilePath $OutFilePath
}