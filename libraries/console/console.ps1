Import-Module Command

enum ConsoleType {
    Ask
    Cmd
    Info
    Pass
    Warn
    Fail
    None
}

function Get-FgColor (
    [Parameter(Mandatory = $false)] [ConsoleType] $ConsoleType = [ConsoleType]::None
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    function Get-ColorFromConfig($key) {
        if (-not $Config -or
            -not $Config['console'] -or
            -not $Config['console']['color']) {
            Write-Debug "No console color defined for $key.."
            $null
        } else {
            $Config['console']['color'][$key]
        }
    }

    switch ($ConsoleType) {
        ([ConsoleType]::Ask) { Get-ColorFromConfig 'ask' }
        ([ConsoleType]::Cmd) { Get-ColorFromConfig 'cmd' }
        ([ConsoleType]::Info) { Get-ColorFromConfig 'info' }
        ([ConsoleType]::Pass) { Get-ColorFromConfig 'pass' }
        ([ConsoleType]::Warn) { Get-ColorFromConfig 'warn' }
        ([ConsoleType]::Fail) { Get-ColorFromConfig 'fail' }
        Default { $null }
    }
}

# console command

function Get-ConsoleCommand (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [string] $WorkingDir
    , [Parameter(Mandatory = $false)] [switch] $SkipPrint
    , [Parameter(Mandatory = $false)] [ConsoleType] $ConsoleType = [ConsoleType]::Cmd
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $command = [Command]::new()
    $command.Line = $Line
    $command.WorkingDir = $WorkingDir
    $command.SkipPrint = $SkipPrint
    $command.FgColor = Get-FgColor $ConsoleType $Config
    $command.BgColor = $null
    $command
}

function Get-ConsoleCommandAsRoot (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [string] $WorkingDir
    , [Parameter(Mandatory = $false)] [switch] $SkipPrint
    , [Parameter(Mandatory = $false)] [ConsoleType] $ConsoleType = [ConsoleType]::Cmd
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Get-ConsoleCommand `
        -Line (Format-AsSudo $Line) `
        -WorkingDir $WorkingDir `
        -SkipPrint:$SkipPrint `
        -ConsoleType $ConsoleType `
        -Config $Config
}

function Invoke-LineAsCommandOnConsole (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [string] $WorkingDir
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $command = Get-ConsoleCommand `
        -Line $Line `
        -WorkingDir $WorkingDir `
        -Config $Config

    Invoke-CommandsConcurrent `
        -Commands $command `
        -WhatIf:$WhatIf
}

function Invoke-LineAsCommandOnConsoleAsRoot (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [string] $WorkingDir
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-LineAsCommandOnConsole `
        -Line (Format-AsSudo $Line) `
        -WorkingDir $WorkingDir `
        -WhatIf:$WhatIf `
        -Config $Config
}

# write-host

function Write-HostAsk (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-FgColor ([ConsoleType]::Ask) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostInfo (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-FgColor ([ConsoleType]::Info) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostPass (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-FgColor ([ConsoleType]::Pass) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostWarn (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-FgColor ([ConsoleType]::Warn) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostFail (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-FgColor ([ConsoleType]::Fail) $Config) `
        -NoNewline:$NoNewLine
}