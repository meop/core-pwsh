#Requires -RunAsAdministrator
# only works on Windows, but others can just use sudo

if ($PSEdition -ne 'Core') {
    Write-Output 'Please install and use PS Core: https://github.com/PowerShell/PowerShell'
    Write-Output 'You are using:'
    Write-Output $PSVersionTable
    exit
}

function Invoke-SafeAppendToPath ($p) {
    $splitter = $IsWindows ? ';' : ':'
    if (Test-Path $p) {
        $env:PATH += "$splitter$p"
    }
}

function Invoke-SafeAppendToModulePath ($p) {
    $splitter = $IsWindows ? ';' : ':'
    if (Test-Path $p) {
        $env:PSModulePath += "$splitter$p"
    }
}

function Invoke-SafeGetCommandPath ($n, $p) {
    $c = Get-Command -Name $n -ErrorAction SilentlyContinue
    $c ? $c.Source : $p
}

function Invoke-SafeCheckCommandPathEqual ($n, $p) {
    $c = Get-Command -Name $n -ErrorAction SilentlyContinue
    $c ? ((Resolve-Path $c.Source).Path).ToLowerInvariant() -eq $p.ToLowerInvariant() : $false
}

function Invoke-SafeGetContent ($p, [switch] $r) {
    (Test-Path $p) ? (Get-Content -Path $p -Raw:$r) : (Write-Output $null)
}

function Invoke-SafeInstallModule ($n, $v = 0) {
    if (-not (Get-Module -ListAvailable -Name $n)) {
        Install-Module -Scope CurrentUser -AllowClobber -AllowPrerelease -Name $n
    } elseif (-not (((Get-Module -ListAvailable -Name $n).Version.Major) -ge $v)) {
        Update-Module -AllowPrerelease -Name $n
    }
}

function Invoke-SafeSetItem ($i, $v) {
    try {
        Get-Item -Path $i -ErrorAction Stop | Out-Null
    } catch {
        Set-Item -Path $i -Value $v
    }
}

Invoke-SafeSetItem 'env:HOSTNAME' (hostname).ToLowerInvariant()
Invoke-SafeSetItem 'env:USERNAME' (($IsWindows) ? $env:USERNAME : $env:USER).ToLowerInvariant()
Invoke-SafeSetItem 'env:OS_ID' (($IsWindows) ? 'windows' : (($IsMacOS) ? 'macos' : (Get-Content '/etc/os-release' | Select-String '^ID=').Line.Split('=')[1]))

Invoke-SafeAppendToModulePath "$PSScriptRoot/Modules"

$f = "$PSScriptRoot/Libraries/source.ps1"
if (Test-Path $f) { . $f }

$d = "$PSScriptRoot/Initializers"
if (Test-Path $d) {
    Get-ChildItem -Path $d -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
}
