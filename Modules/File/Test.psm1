function Test-PathAsRoot (
    [Parameter(Mandatory = $true)] [string] $Path
    , [Parameter(Mandatory = $false)] [Microsoft.PowerShell.Commands.TestPathType] $PathType = [Microsoft.PowerShell.Commands.TestPathType]::Any
) {
    function Test ($t) {
        Invoke-Command -ScriptBlock (
            [scriptblock]::create(
                (Format-AsSudo -Line "test -$t `"$Path`" && echo 1")
            )
        )
    }

    function TestContainer {
        Test 'd'
    }

    function TestLeaf {
        Test 'f'
    }

    if ($IsWindows) {
        Test-Path -Path $Path -PathType $PathType
    } else {
        switch ($PathType) {
            ([Microsoft.PowerShell.Commands.TestPathType]::Any) {
                ((TestContainer) -or (TestLeaf))
            }
            ([Microsoft.PowerShell.Commands.TestPathType]::Container) {
                (TestContainer)
            }
            ([Microsoft.PowerShell.Commands.TestPathType]::Leaf) {
                (TestLeaf)
            }
        }
    }
}