function Format-AsSudo (
    [Parameter(Mandatory = $true)] [string] $Line
) {
    $IsWindows ? $Line : "sudo sh -c ' $Line '"
}