function Test-PathIsOfType (
    [Parameter(Mandatory = $true)] [string] $Path
    , [Parameter(Mandatory = $false)] [Microsoft.PowerShell.Commands.TestPathType] $PathType = [Microsoft.PowerShell.Commands.TestPathType]::Any
) {
    [System.Convert]::ToBoolean((Test-Path $Path -PathType $PathType))
}