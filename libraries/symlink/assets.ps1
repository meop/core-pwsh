function Get-SymlinkGroup {
    Import-Csv "$(Get-ProfileAssetsDir)/symlinks.csv"
}