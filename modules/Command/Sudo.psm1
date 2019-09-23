function Format-AsSudo (
    [Parameter(Mandatory = $true)] [string] $Line
) {
    if (-not $IsWindows) {
        "sudo bash -c ' $Line '"
    } else {
        $Line
    }
}