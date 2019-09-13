function Import-AssetCsv (
    [Parameter(Mandatory = $true)] [string] $Path
) {
    $path = ConvertTo-CrossPlatformPathFormat `
        $(if ($Path.EndsWith('.csv')) { $Path } else { "$Path.csv" })

    if (Test-Path $path) {
        Import-Csv $path
    } else {
        $null
    }
}

function Import-AssetList (
    [Parameter(Mandatory = $true)] [string] $Path
) {
    $path = ConvertTo-CrossPlatformPathFormat `
        $(if ($Path.EndsWith('.txt')) { $Path } else { "$Path.txt" })

    if (Test-Path $path) {
        $items = Get-Content $path | Where-Object {
            $_.Trim() -ne '' -and -not $_.StartsWith(';')
        }
    }

    if ($items) {
        $items | ForEach-Object {
            (ConvertTo-CrossPlatformPathFormat $_)
        }
    } else {
        Write-Debug "no viable items found in: $path"
        @()
    }
}

function Update-AssetCacheFile (
    [Parameter(Mandatory = $true)] [string] $Include
    , [Parameter(Mandatory = $true)] [string[]] $SearchPaths
    , [Parameter(Mandatory = $true)] [string] $OutFilePath
    , [Parameter(Mandatory = $false)] [switch] $StoreParentPath
) {
    $files = @()
    $SearchPaths | ForEach-Object {
        (Invoke-FindFilePathsMatchingPattern -Include $Include -Path $_ -Depth 100) | ForEach-Object {
            $path = if ($StoreParentPath.IsPresent) { Split-Path $_ } else { $_ }
            $files += ConvertTo-CrossPlatformPathFormat $path
        }
    }

    $files | Out-File -FilePath $OutFilePath
}

function Get-AssetBatchFilePaths (
    [Parameter(Mandatory = $true)] [string] $Path
    , [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
) {
    $items = Import-AssetList $Path
    if (-not $items) { return }

    Merge-ItemsByAggregateFilters `
        -Items $items `
        -Filters $Filters `
        -UnionFilters:$UnionFilters
}

function Get-AssetGroupFilePaths (
    [Parameter(Mandatory = $true)] [string] $Path
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
) {
    $items = Import-AssetList $Path
    if (-not $items) { return }

    Select-ItemsByRangeFilters `
        -Items $items `
        -StartName $StartName `
        -StopName $StopName
}
