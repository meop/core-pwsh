Import-Module Command

enum Console {
    None
    Ask
    Cmd
    Info
    Pass
    Warn
    Fail
}

function Get-ForegroundColor (
    [Parameter(Mandatory = $false)] [Console] $Console = [Console]::None
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

    switch ($Console) {
        ([Console]::Ask) { Get-ColorFromConfig 'ask' }
        ([Console]::Cmd) { Get-ColorFromConfig 'cmd' }
        ([Console]::Info) { Get-ColorFromConfig 'info' }
        ([Console]::Pass) { Get-ColorFromConfig 'pass' }
        ([Console]::Warn) { Get-ColorFromConfig 'warn' }
        ([Console]::Fail) { Get-ColorFromConfig 'fail' }
        Default { $null }
    }
}

# console command

function Get-ConsoleCommand (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [string] $WorkingDir
    , [Parameter(Mandatory = $false)] [Console] $Console = [Console]::Cmd
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $command = [Command]::new()
    $command.Line = $Line
    $command.WorkingDir = $WorkingDir
    $command.ForegroundColor = Get-ForegroundColor $Console $Config
    $command.BackgroundColor = $null
    $command
}

function Invoke-LineAsCommandOnConsole (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [string] $WorkingDir
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Invoke-CommandsConcurrent `
        -Commands (Get-ConsoleCommand `
            -Line $Line `
            -WorkingDir $WorkingDir `
            -Config $Config) `
        -WhatIf:$WhatIf
}

# write-host

function Write-HostAsk (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-ForegroundColor ([Console]::Ask) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostInfo (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-ForegroundColor ([Console]::Info) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostPass (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-ForegroundColor ([Console]::Pass) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostWarn (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-ForegroundColor ([Console]::Warn) $Config) `
        -NoNewline:$NoNewLine
}

function Write-HostFail (
    [Parameter(Mandatory = $true)] [string] $Line
    , [Parameter(Mandatory = $false)] [switch] $NoNewLine
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Write-Host $line `
        -ForegroundColor (Get-ForegroundColor ([Console]::Fail) $Config) `
        -NoNewline:$NoNewLine
}