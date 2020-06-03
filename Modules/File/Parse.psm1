function Invoke-CheckFileForDuplicateLines (
    [Parameter(Mandatory = $true)] [string] $Path
) {
    Get-Content -Path $Path | Group-Object | Where-Object { $_.count -gt 1 }
}