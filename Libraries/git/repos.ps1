function Update-GitReposList (
    [Parameter(Mandatory = $true)] [string] $OutFilePath
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Update-AssetList `
        -Include '.git' `
        -SearchPaths $Config['git']['searchPaths'] `
        -OutFilePath $OutFilePath `
        -StoreParentPath $true
}