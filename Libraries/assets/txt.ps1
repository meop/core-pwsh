function Import-AssetList (
    [Parameter(Mandatory = $true)] [string] $Path
    , [Parameter(Mandatory = $false)] [string] $Extension = '.txt'
    , [Parameter(Mandatory = $false)] [string] $CommentedLinePrefix = ';'
    , [Parameter(Mandatory = $false)] [bool] $ValuesArePaths = $true
) {
    $path = ConvertTo-CrossPlatformPathFormat `
        ($Path.EndsWith($Extension) ? $Path : "$Path$Extension")

    if (Test-Path $path) {
        $items = Get-Content $path | Where-Object {
            $_.Trim() -ne '' -and -not $_.StartsWith($CommentedLinePrefix)
        }
    }

    if ($items) {
        $items | ForEach-Object {
            $ValuesArePaths ? (ConvertTo-CrossPlatformPathFormat $_) : $_
        }
    } else {
        Write-Debug "no viable items found in: $path"
        @()
    }
}

function Update-AssetList (
    [Parameter(Mandatory = $true)] [string] $Include
    , [Parameter(Mandatory = $true)] [string[]] $SearchPaths
    , [Parameter(Mandatory = $true)] [string] $OutFilePath
    , [Parameter(Mandatory = $false)] [bool] $StoreParentPath = $false
) {
    $files = @()
    $SearchPaths | ForEach-Object {
        (Invoke-FindFilePathsMatchingPattern -Include $Include -Path $_ -Depth 100) | ForEach-Object {
            $path = $StoreParentPath ? (Split-Path $_) : $_
            $files += ConvertTo-CrossPlatformPathFormat $path
        }
    }

    $files | Out-File -FilePath $OutFilePath
}

function Get-AssetListBatch (
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

function Get-AssetListGroup (
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
