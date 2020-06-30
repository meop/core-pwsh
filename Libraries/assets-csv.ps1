function Import-AssetCsv (
    [Parameter(Mandatory = $true)] [string] $Path
    , [Parameter(Mandatory = $false)] [string] $Extension = '.csv'
) {
    $path = ConvertTo-CrossPlatformPathFormat `
        ($Path.EndsWith($Extension) ? $Path : "$Path$Extension")

    (Test-Path $path) ? (Import-Csv $path) : $null
}