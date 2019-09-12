# note AnalyticSummary.Web runs its post build copy routine after evaluating
#  if this variable is set to "" or not.. so $false is safe here too..
# note also: MSBuild cannot handle 0 or 1, only 'true' or 'false'..
#  case doesn't matter, but must be these strings
$env:BuildingInsideVisualStudio = $false

class VsToolFilePaths {
    [string] $VsDevCmd
    [string] $MsBuild
    [string] $SqlPackage
}

function Get-VsToolFilePathsLatest (
    [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    [VsToolFilePaths] @{
        VsDevCmd    = $Config['vsDevCmd']['filePath']['latest']
        MsBuild     = $Config['msBuild']['filePath']['latest']
        SqlPackage  = $Config['sqlPackage']['filePath']['latest']
    }
}

function Get-VsToolFilePathsProject (
    [Parameter(Mandatory = $true)] [string] $Project
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $projectMap = (Get-MSBuildProjectsMap) | Where-Object {
        $_.Project.ToLowerInvariant().Contains($Project.ToLowerInvariant())
    }

    $vsVersion = if ($projectMap) { $projectMap.VsVersion } else { 'latest' }

    [VsToolFilePaths] @{
        VsDevCmd    = $Config['vsDevCmd']['filePath'][$vsVersion]
        MsBuild     = $Config['msBuild']['filePath'][$vsVersion]
        SqlPackage  = $Config['sqlPackage']['filePath'][$vsVersion]
    }
}

class MsBuildParameters {
    [string] $Action
    [string] $Verbosity
    [int] $MaxThreads
    [string] $Config
    [bool] $InParallel
    [bool] $UseEnv
    [bool] $UseSharedCompilation
    [string] $LogsDir

    [bool] $PrintErrors
    [bool] $PrintWarnings
}

function Get-MsBuildParametersDefault (
    [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $msBuild = $Config['msBuild']
    $msBuildDefault = $msBuild['default']
    $msBuildPrint = $msBuild['print']

    [MsBuildParameters] @{
        Action               = $msBuildDefault['action']
        Verbosity            = $msBuildDefault['verbosity']
        MaxThreads           = $msBuildDefault['maxThreads']
        Config               = $msBuildDefault['buildConfig']
        InParallel           = $msBuildDefault['buildInParallel']
        UseEnv               = $msBuildDefault['useEnv']
        UseSharedCompilation = $msBuildDefault['useSharedCompilation']
        LogsDir              = $msBuildDefault['logsPath']

        PrintWarnings        = $msBuildPrint['warnings']
        PrintErrors          = $msBuildPrint['errors']
    }
}

function Invoke-MsBuild (
    [Parameter(Mandatory = $true)] [string] $Project
    , [Parameter(Mandatory = $false)] [MsBuildParameters] $MsBuildParameters
    , [Parameter(Mandatory = $false)] [VsToolFilePaths] $VsToolFilePaths
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not (Test-Path $Project) -and -not $WhatIf.IsPresent) {
        Write-Output "skipping - project not found: $Project"
        return
    }

    if (-not $MsBuildParameters) {
        $MsBuildParameters = Get-MsBuildParametersDefault -Config $Config
    }

    if (-not $VsToolFilePaths) {
        $VsToolFilePaths = Get-VsToolFilePathsProject -Project $Project -Config $Config
    }

    $baseLogFileDir = ConvertTo-BackwardSlashes $MsBuildParameters.LogsDir
    if (-not $WhatIf.IsPresent) {
        if (-not (Test-Path $baseLogFileDir)) {
            New-Item -ItemType Directory -Force -Path $baseLogFileDir | Out-Null
        }
    }

    $projectDir = Split-Path $Project -Leaf
    $projectLogPrefix = ConvertTo-BackwardSlashes "$baseLogFileDir/$projectDir"

    $logFilePath = "$projectLogPrefix.log"
    $warnLogFilePath = "$projectLogPrefix.warn.log"
    $failLogFilePath = "$projectLogPrefix.fail.log"

    if (-not $WhatIf.IsPresent) {
        if (Test-Path $logFilePath) {
            Remove-Item $logFilePath
        }
        if (Test-Path $warnLogFilePath) {
            Remove-Item $warnLogFilePath
        }
        if (Test-Path $failLogFilePath) {
            Remove-Item $failLogFilePath
        }
    }

    Write-HostInfo "BEGIN building $Project" `
        -Config $Config

    $msBuildLaunchSection =
    if (Invoke-SafeCheckCommandPathEqual 'vsdevcmd' $VsToolFilePaths.VsDevCmd) {
        if (Invoke-SafeCheckCommandPathEqual 'msbuild' $VsToolFilePaths.MsBuild) {
            " `"`"$((Get-Command 'msbuild').Source)`"`" "
        } else {
            " `"`"$($VsToolFilePaths.MsBuild)`"`" "
        }
    } else {
        " `"`"$($VsToolFilePaths.VsDevCmd)`"`" & `"`"$($VsToolFilePaths.MsBuild)`"`" "
    }

    $line = "cmd /c `" $msBuildLaunchSection `"`"$Project`"`" /target:$($MsBuildParameters.Action) /verbosity:$($MsBuildParameters.Verbosity) /maxCpuCount:$($MsBuildParameters.MaxThreads) /property:Configuration=$($MsBuildParameters.Config);BuildInParallel=$($MsBuildParameters.InParallel);UseEnv=$($MsBuildParameters.UseEnv);UseSharedCompilation=$($MsBuildParameters.UseSharedCompilation) /noLogo /noConsoleLogger /fileLoggerParameters:LogFile=`"`"$logFilePath`"`" /fileLoggerParameters1:LogFile=`"`"$warnLogFilePath`"`";WarningsOnly /fileLoggerParameters2:LogFile=`"`"$failLogFilePath`"`";ErrorsOnly `""

    Invoke-LineAsCommandOnConsole `
        -Line $line `
        -WhatIf:$WhatIf `
        -Config $Config

    Write-HostInfo "END building $Project" `
        -Config $Config

    if ($WhatIf.IsPresent) {
        return
    }

    $warned = ((Test-Path $warnLogFilePath) -and ((Get-Item $warnLogFilePath).Length -gt 0))
    $failed = ((Test-Path $failLogFilePath) -and ((Get-Item $failLogFilePath).Length -gt 0))

    if ($MsBuildParameters.PrintWarnings -and $warned) {
        Write-Host
        Write-HostWarn (Get-Content $warnLogFilePath -Raw) `
            -Config $Config
    }
    if ($MsBuildParameters.PrintErrors -and $failed) {
        Write-Host
        Write-HostFail (Get-Content $failLogFilePath -Raw) `
            -Config $Config
    }

    Write-Host
    if ($failed) {
        Write-HostFail "Build failed" `
            -Config $Config
    } else {
        Write-HostPass "Build passed" `
            -Config $Config
    }
    Write-Host
}

function Invoke-MsBuildBatch (
    [Parameter(Mandatory = $false)] [string[]] $Filters
    , [Parameter(Mandatory = $false)] [switch] $UnionFilters
    , [Parameter(Mandatory = $false)] [MsBuildParameters] $MsBuildParameters
    , [Parameter(Mandatory = $false)] [VsToolFilePaths] $VsToolFilePaths
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $items = Get-MsBuildProjectsBatchFilePaths `
        -Filters $Filters `
        -UnionFilters:$UnionFilters

    foreach ($item in $items) {
        Invoke-MsBuild `
            -Project $item `
            -MsBuildParameters $MsBuildParameters `
            -VsToolFilePaths $VsToolFilePaths `
            -WhatIf:$WhatIf `
            -Config $Config
    }
}

function Invoke-MsBuildGroup (
    [Parameter(Mandatory = $true)] [string] $GroupName
    , [Parameter(Mandatory = $false)] [string] $StartName
    , [Parameter(Mandatory = $false)] [string] $StopName
    , [Parameter(Mandatory = $false)] [MsBuildParameters] $MsBuildParameters
    , [Parameter(Mandatory = $false)] [VsToolFilePaths] $VsToolFilePaths
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $items = Get-MsBuildProjectsGroupFilePaths `
        -GroupName $GroupName `
        -StartName $StartName `
        -StopName $StopName

    foreach ($item in $items) {
        Invoke-MsBuild `
            -Project $item `
            -MsBuildParameters $MsBuildParameters `
            -VsToolFilePaths $VsToolFilePaths `
            -WhatIf:$WhatIf `
            -Config $Config
    }
}