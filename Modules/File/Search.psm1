function Invoke-FindFilePathsMatchingPattern (
    [Parameter(Mandatory = $true)] [string] $Include
    , [Parameter(Mandatory = $false)] [string] $Path = $pwd
    , [Parameter(Mandatory = $false)] [int] $Depth = 1
) {
    # note: Include actually requires Recurse to find matches
    # note: Force is required to find Hidden items
    Get-ChildItem -Force -Path $Path -Recurse -Include $Include -Depth $Depth |
    Select-Object -ExpandProperty FullName
}

function Invoke-FindFilePathsMatchingPatternUnions(
    [Parameter(Mandatory = $true)] [string] $Include
    , [Parameter(Mandatory = $false)] [string] $Path = $pwd
    , [Parameter(Mandatory = $false)] [int] $Depth = 1
    , [Parameter(Mandatory = $false)] [string[]] $With
    , [Parameter(Mandatory = $false)] [switch] $UnionWith
    , [Parameter(Mandatory = $false)] [string[]] $Without
    , [Parameter(Mandatory = $false)] [switch] $UnionWithout
) {
    Get-ChildItem -Force -Path $Path -Recurse -Include $Include -Depth $Depth |
    ForEach-Object {
        $withMatch = $withoutMatch = $true

        if ($With) {
            $withMatch = if ($UnionWith.IsPresent) { $true } else { $false }
            foreach ($w in $With) {
                if ($UnionWith.IsPresent) {
                    $withMatch = $withMatch -and (Select-String $w $_ -Quiet)
                } else {
                    $withMatch = $withMatch -or (Select-String $w $_ -Quiet)
                }
            }
        }

        if ($Without -and $withMatch) {
            $withoutMatch = if ($UnionWithout.IsPresent) { $true } else { $false }
            foreach ($wo in $Without) {
                if ($UnionWithout.IsPresent) {
                    $withoutMatch = $withoutMatch -and -not (Select-String $wo $_ -Quiet)
                } else {
                    $withoutMatch = $withoutMatch -or -not (Select-String $wo $_ -Quiet)
                }
            }
        }

        if ($withMatch -and $withoutMatch) {
            Write-Output $_.FullName
        }
    }
}