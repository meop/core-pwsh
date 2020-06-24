class VsToolFilePaths {
    [string] $VsDevCmd
    [string] $MsBuild
    [string] $SqlPackage
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

function Get-MsBuildDefaultParameters (
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

function Get-MsBuildDefaultVsToolFilePaths (
    [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    [VsToolFilePaths] @{
        VsDevCmd   = $Config['vsDevCmd']['filePath']['latest']
        MsBuild    = $Config['msBuild']['filePath']['latest']
        SqlPackage = $Config['sqlPackage']['filePath']['latest']
    }
}

function Invoke-MsBuild (
    [Parameter(Mandatory = $true)] [string] $Project
    , [Parameter(Mandatory = $false)] [VsToolFilePaths] $VsToolFilePaths
    , [Parameter(Mandatory = $false)] [MsBuildParameters] $MsBuildParameters
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not (Test-Path $Project) -and -not $WhatIf.IsPresent) {
        Write-Output "skipping - project not found: $Project"
        return
    }

    if (-not $VsToolFilePaths) {
        $VsToolFilePaths = Get-MsBuildDefaultVsToolFilePaths -Config $Config
    }

    if (-not $MsBuildParameters) {
        $MsBuildParameters = Get-MsBuildDefaultParameters -Config $Config
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
        " set __VSCMD_ARG_NO_LOGO=1 && `"`"$($VsToolFilePaths.VsDevCmd)`"`" && `"`"$($VsToolFilePaths.MsBuild)`"`" "
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