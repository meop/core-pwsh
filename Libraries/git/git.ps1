function Invoke-GitRebaseWithRetries (
    [Parameter(Mandatory = $true)] [string] $RepoDir
    , [Parameter(Mandatory = $true)] [string] $TargetBranch = 'origin/master'
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    if (-not (Test-Path $repoDir) -and -not $WhatIf.IsPresent) {
        Write-Output "skipping - directory not found: $repoDir"
        return
    }

    $outFile = 'git.rebase.out'
    $outFilePath = "$repoDir/$outFile"

    if (Test-Path $outFilePath) { Remove-Item $outFilePath }

    $runComplete = $false
    $runFresh = $true
    $rebaseOption = ''

    do {
        $operation = $runFresh ? "rebase $TargetBranch" : "rebase --$rebaseOption"
        $line = "git $operation *> $outFile"

        Invoke-LineAsCommandOnConsole `
            -Line $line `
            -WorkingDir $repoDir `
            -WhatIf:$WhatIf `
            -Config $Config

        $outFileLines = @()
        if (Test-Path $outFilePath) {
            $outFileLines = Get-Content $outFilePath
            Write-Output $outFileLines
        }

        $runComplete = $true
        $runFresh = $false

        foreach ($line in $outFileLines) {
            if (
                ($line -like '*Cannot rebase*') -or
                ($line -like '*fatal:*')
            ) {
                Write-Host
                Write-HostFail $line `
                    -Config $Config
                Write-Host

                $runFresh = $true

                Write-HostAsk 'Retry with another pass ([Y]es/[n]o): ' `
                    -NoNewline `
                    -Config $Config

                $ans = Read-Host
                $runComplete =
                    if ($ans -like '*n*') { $true }
                    else { $false }

                break
            }

            if (
                ($line -like '*already a rebase*') -or
                ($line -like '*CONFLICT*') -or
                ($line -like '*error:*')
            ) {
                Write-Host
                Write-HostWarn $line `
                    -Config $Config
                Write-Host

                $runComplete = $false

                $line = 'git mergetool'

                Invoke-LineAsCommandOnConsole `
                    -Line $line `
                    -WorkingDir $repoDir `
                    -WhatIf:$WhatIf `
                    -Config $Config

                Write-HostAsk 'Rebase option for next pass ([C]ontinue/[s]kip/[a]bort): ' `
                    -NoNewline `
                    -Config $Config

                $ans = Read-Host
                $rebaseOption =
                    if ($ans -like '*s*') { 'skip' }
                    elseif ($ans -like '*a*') { 'abort' }
                    else { 'continue' }

                break
            }
        }
    } while (-not $runComplete)

    if (Test-Path $outFilePath) { Remove-Item $outFilePath }
}