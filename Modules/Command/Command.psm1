function expand (
    [Parameter(Mandatory = $true)] [Command] $Command
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
) {
    $line = $Command.Line
    $workingDir = $Command.WorkingDir

    $expanded =
    if ($workingDir) {
        if (Test-Path $workingDir) {
            "Push-Location '$workingDir'; $line; Pop-Location;"
        } else {
            "Write-Output 'skipping - path does not exist: $workingDir'"
        }
    } else {
        $line
    }

    $expanded
}

function print (
    [Parameter(Mandatory = $true)] [Command] $Command
) {
    $props = @{
        Object = expand $Command
    }

    if ($Command.FgColor) {
        $props.Add('ForegroundColor', $Command.FgColor)
    }
    if ($Command.BackgroundColor) {
        $props.Add('BackgroundColor', $Command.BgColor)
    }

    Write-Host @props
}

function Invoke-CommandsConcurrent (
    [Parameter(Mandatory = $false)] [Command[]] $Commands
    , [Parameter(Mandatory = $false)] [int] $ThrottleLimit = 8
    , [Parameter(Mandatory = $false)] [int] $StatusCheckDelayInMilliseconds = 100
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
) {
    if (-not $Commands) { return }

    if ($WhatIf.IsPresent) {
        foreach ($command in $Commands) {
            if (-not $command.SkipPrint.IsPresent) {
                print -Command $command
            }
        }
        return
    }

    # if just 1 command, execute in foreground
    # faster, and allows full i/o access
    if ($Commands.Length -eq 1) {
        $command = $Commands[0]
        if (-not $command.SkipPrint.IsPresent) {
            print -Command $command
        }
        Invoke-Command -ScriptBlock (
            [scriptblock]::Create(
                (expand -Command $command -WhatIf:$WhatIf)
            )
        )
        return
    }

    $jobsCount = $Commands.Length
    $jobsQueue = New-Object System.Collections.Queue

    for ($i = 0; $i -lt $jobsCount; ++$i) {
        $props = @{
            ScriptBlock = (
                [scriptblock]::Create(
                    (expand -Command $Commands[$i] -WhatIf:$WhatIf)
                )
            )
        }
        if ($i -eq 0) {
            $props.Add('ThrottleLimit', $ThrottleLimit)
        }
        $jobsQueue.Enqueue((Start-ThreadJob @props))
    }

    while ($jobsQueue.Count -gt 0) {
        print -Command $Commands[$jobsCount - $jobsQueue.Count]
        $job = $jobsQueue.Dequeue()

        $done = $false
        while (-not $done) {
            Start-Sleep -Milliseconds $StatusCheckDelayInMilliseconds
            $jobStatus = $job | Get-Job
            if ($jobStatus.HasMoreData) {
                $job | Receive-Job
            }

            # note: this code is not written to handle errors
            # no try/catch, no checking other states
            # could be added if desired
            if ($jobStatus.State -eq 'Completed') {
                $done = $true

                $job | Remove-Job
            }
        }
    }
}

Export-ModuleMember -Function Invoke-CommandsConcurrent