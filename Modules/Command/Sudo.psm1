function Format-AsSudo (
    [Parameter(Mandatory = $true)] [string] $Line
) {
    $IsWindows ? $Line : "sudo bash -c ' $Line '"
}