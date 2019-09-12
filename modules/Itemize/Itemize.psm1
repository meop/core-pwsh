function Merge-ItemsByAggregateFilters (
    [Parameter(Mandatory = $true)] [string[]] $Items
    , [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
) {
    if (-not $Items) { return @() }

    $aggregateItems = @()

    if (-not $Filters) {
        $aggregateItems = $Items
    } else {
        $processedFirstFilter = $false
        foreach ($filter in $Filters) {
            $filteredItems = $Items | Select-String $filter

            if ($UnionFilters.IsPresent) {
                if (-not $aggregateItems) {
                    $aggregateItems = $filteredItems
                } elseif ($filteredItems) {
                    $aggregateItems = Compare-Object `
                        $aggregateItems $filteredItems `
                        -PassThru -IncludeEqual
                }
            } else {
                if (-not $processedFirstFilter) {
                    $aggregateItems = $filteredItems
                    $processedFirstFilter = $true
                } elseif (-not $aggregateItems -or -not $filteredItems) {
                    $aggregateItems = $null
                } else {
                    $aggregateItems = Compare-Object `
                        $aggregateItems $filteredItems `
                        -PassThru -IncludeEqual -ExcludeDifferent
                }
            }
            $aggregateItems = $aggregateItems | Select-Object -Unique
        }
    }

    $aggregateItems
}

function Select-ItemsByRangeFilters (
    [Parameter(Mandatory = $true)] [string[]] $Items
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
) {
    if (-not $Items) { return @() }

    $results = @()

    if ($StartName -or $StopName) {
        $recording = [bool](-not $StartName)
        foreach ($item in $Items) {
            if (-not $recording -and ($item -match $StartName)) {
                $recording = $true
            }
            if ($recording) {
                $results += $item
            }
            if ($StopName -and ($item -match $StopName)) {
                break
            }
        }
    } else {
        $results = $Items
    }

    $results
}