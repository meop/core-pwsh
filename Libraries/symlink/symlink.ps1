function Get-SymlinkLine (
    [Parameter(Mandatory = $true)] $Path
    , [Parameter(Mandatory = $true)] $TargetPath
    , [Parameter(Mandatory = $false)] [switch] $AsSudo
) {
    $line = (Test-Path $TargetPath) `
        ? "New-Item -Force -Path '$Path' -Value '$TargetPath' -ItemType SymbolicLink | Out-Null" `
        : "Write-Output 'skipping - target path does not exist: $TargetPath'"

    if ($AsSudo.IsPresent) {
        $line = Format-AsSudo $line
    }

    $line
}