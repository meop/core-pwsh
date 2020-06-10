function expandCommand (
    [Parameter(Mandatory = $true)] [Command] $Command
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

    $onEnqueue = {
        param($index)

        $command = $Commands[$index]
        if ($WhatIf.IsPresent) {
            printCommand -Command $command
        }
    }

    $onDequeue = {
        param($index)

        $command = $Commands[$index]
        printCommand -Command $command
    }

    Invoke-ScriptBlocksConcurrent `
        -ScriptBlocks $scriptblocks `
        -OnEnqueue $onEnqueue `
        -OnDequeue $onDequeue `
        -ThrottleLimit $ThrottleLimit `
        -PollingDelayInMs $PollingDelayInMs`
        -WhatIf:$WhatIf
}

function Invoke-ScriptBlocksConcurrent (
    [Parameter(Mandatory = $false)] [scriptblock[]] $ScriptBlocks
    , [Parameter(Mandatory = $false)] [object[]] $ArgumentLists
    , [Parameter(Mandatory = $false)] [scriptblock] $OnEnqueue
    , [Parameter(Mandatory = $false)] [scriptblock] $OnDequeue
    , [Parameter(Mandatory = $false)] [int] $ThrottleLimit = 8
    , [Parameter(Mandatory = $false)] [int] $PollingDelayInMs = 100
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
) {
    if (-not $ScriptBlocks) { return }

    # if just 1 block, execute in foreground
    # faster, and allows full i/o access
    if ($ScriptBlocks.Length -eq 1) {
        $scriptblock = $ScriptBlocks[0]

        if ($OnDequeue) {
            Invoke-Command $OnDequeue -ArgumentList 0
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

        if ($OnEnqueue) {
            Invoke-Command $OnEnqueue -ArgumentList $i
        }

        if (-not $WhatIf.IsPresent) {
            $jobsQueue.Enqueue((Start-ThreadJob @props))
        }
    }

    while ($jobsQueue.Count -gt 0) {
        if ($OnDequeue) {
            Invoke-Command $OnDequeue -ArgumentList ($jobsCount - $jobsQueue.Count)
        }

        $job = $jobsQueue.Dequeue()

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
    }
}

Export-ModuleMember -Function Invoke-CommandsConcurrent, Invoke-ScriptBlocksConcurrent