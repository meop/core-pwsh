function expandCommand (
    [Parameter(Mandatory = $true)] [Command] $Command
) {
    $line = $Command.Line
    $workingDir = $Command.WorkingDir

    $expanded = $workingDir `
        ? (Test-Path $workingDir) `
            ? "Push-Location '$workingDir'; $line; Pop-Location;" `
            : "Write-Output 'skipping - path does not exist: $workingDir'"
        : $line

    $expanded
}

function printCommand (
    [Parameter(Mandatory = $true)] [Command] $Command
) {
    $props = @{
        Object = expandCommand $Command
    }

    if ($Command.ForegroundColor) {
        $props.Add('ForegroundColor', $Command.ForegroundColor)
    }
    if ($Command.BackgroundColor) {
        $props.Add('BackgroundColor', $Command.BackgroundColor)
    }

    Write-Host @props
}

function Invoke-CommandsConcurrent (
    [Parameter(Mandatory = $false)] [Command[]] $Commands
    , [Parameter(Mandatory = $false)] [scriptblock[]] $OnEnqueues
    , [Parameter(Mandatory = $false)] [scriptblock[]] $OnDequeues
    , [Parameter(Mandatory = $false)] [string] $Activity
    , [Parameter(Mandatory = $false)] [int] $ThrottleLimit = 8
    , [Parameter(Mandatory = $false)] [int] $PollingDelayInMs = 100
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
) {
    if (-not $Commands) { return }

    $scriptblocks = @()
    foreach ($command in $Commands) {
        $scriptblocks += [scriptblock]::Create(
            (expandCommand -Command $command)
        )
    }

    $OnEnqueue = {
        param ($index, $count)

        $command = $Commands[$index]
        if ($WhatIf.IsPresent) {
            printCommand -Command $command
        }
    }

    if ($OnEnqueues) {
        $OnEnqueues += , $OnEnqueue
    } else {
        $OnEnqueues = @(, $OnEnqueue)
    }

    $OnDequeue = {
        param ($index, $count)

        $command = $Commands[$index]
        printCommand -Command $command
    }

    if ($OnDequeues) {
        $OnDequeues += , $OnDequeue
    } else {
        $OnDequeues = @(, $OnDequeue)
    }

    Invoke-ScriptBlocksConcurrent `
        -ScriptBlocks $scriptblocks `
        -OnEnqueues $OnEnqueues `
        -OnDequeues $OnDequeues `
        -Activity $Activity `
        -ThrottleLimit $ThrottleLimit `
        -PollingDelayInMs $PollingDelayInMs`
        -WhatIf:$WhatIf
}

function Invoke-ScriptBlocksConcurrent (
    [Parameter(Mandatory = $false)] [scriptblock[]] $ScriptBlocks
    , [Parameter(Mandatory = $false)] [object[]] $ArgumentLists
    , [Parameter(Mandatory = $false)] [scriptblock[]] $OnEnqueues
    , [Parameter(Mandatory = $false)] [scriptblock[]] $OnDequeues
    , [Parameter(Mandatory = $false)] [string] $Activity
    , [Parameter(Mandatory = $false)] [int] $ThrottleLimit = 8
    , [Parameter(Mandatory = $false)] [int] $PollingDelayInMs = 100
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
) {
    if (-not $ScriptBlocks) { return }

    # if just 1 block, execute in foreground
    # faster, and allows full i/o access
    if ($ScriptBlocks.Length -eq 1) {
        $scriptblock = $ScriptBlocks[0]

        if ($OnDequeues) {
            foreach ($callback in $OnDequeues) {
                Invoke-Command $callback -ArgumentList 0, 1
            }
        }

        if (-not $WhatIf.IsPresent) {
            $props = @{
                ScriptBlock = $scriptblock
            }

            if ($ArgumentLists) {
                $props.Add('ArgumentList', $ArgumentLists[0])
            }

            Invoke-Command @props
        }

        return
    }

    if ($Activity) {
        $Activity = "Activity: $Activity .."
    }

    $jobsCount = $ScriptBlocks.Length
    $jobsQueue = New-Object System.Collections.Queue

    for ($i = 0; $i -lt $jobsCount; ++$i) {
        $props = @{
            ScriptBlock = $ScriptBlocks[$i]
        }

        if ($ArgumentLists) {
            $props.Add('ArgumentList', $ArgumentLists[$i])
        }

        if ($i -eq 0) {
            $props.Add('ThrottleLimit', $ThrottleLimit)
        }

        if (-not $WhatIf.IsPresent) {
            $jobsQueue.Enqueue((Start-ThreadJob @props))
        }

        if ($OnEnqueues) {
            foreach ($callback in $OnEnqueues) {
                Invoke-Command $callback -ArgumentList $i, $jobsCount
            }
        }
    }

    if ($jobsCount -gt 0 -and $Activity) {
        Write-Progress -Activity $Activity -Status "Status: 0 / $jobsCount complete .."
    }

    while ($jobsQueue.Count -gt 0) {
        $job = $jobsQueue.Dequeue()

        $jobsNumber = $jobsCount - $jobsQueue.Count

        if ($OnDequeues) {
            foreach ($callback in $OnDequeues) {
                Invoke-Command $callback -ArgumentList ($jobsNumber - 1), $jobsCount
            }
        }

        $done = $false
        while (-not $done) {
            Start-Sleep -Milliseconds $PollingDelayInMs
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

        if ($Activity) {
            Write-Progress -Activity $Activity -Status "Status: $jobsNumber / $jobsCount complete .."
        }
    }

    if ($jobsCount -gt 0 -and $Activity) {
        Write-Progress -Activity $Activity -Completed
    }
}

Export-ModuleMember -Function Invoke-CommandsConcurrent, Invoke-ScriptBlocksConcurrent