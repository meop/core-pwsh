function Invoke-FindFilePathsMatchingPatternAndReplaceText (
    [Parameter(Mandatory = $true)] [string[]] $Include
    , [Parameter(Mandatory = $true)] [string] $Search
    , [Parameter(Mandatory = $true)] [string] $Replace
    , [Parameter(Mandatory = $false)] [string] $Path = $pwd
    , [Parameter(Mandatory = $false)] [int] $Depth = 1
    , [Parameter(Mandatory = $false)] [string] $Encoding = [System.Text.Encoding]::UTF8
) {
    Invoke-FindFilePathsMatchingPattern -Include $Include -Path $Path -Depth $Depth |
    ForEach-Object {
        $content = Get-Content -Raw -Path $_
        if ($null -ne $content) {
            if ($content.Contains($Search)) {
                $content.Replace($Search, $Replace) |
                Set-Content -NoNewline -Path $_ -Encoding $Encoding
            }
        }
    }
}