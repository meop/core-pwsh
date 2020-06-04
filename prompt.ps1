# Readline colors
Invoke-SafeInstallModule PSReadline 2
Import-Module PSReadline

Set-PSReadlineOption -EditMode Windows

Set-PSReadlineOption -Colors @{
    Command   = [ConsoleColor]::DarkMagenta
    Parameter = [ConsoleColor]::DarkCyan
    Variable  = [ConsoleColor]::Gray
    Comment   = [ConsoleColor]::Blue
    Number    = [ConsoleColor]::Red
    Operator  = [ConsoleColor]::Green
    String    = [ConsoleColor]::Yellow
    Type      = [ConsoleColor]::Cyan
}

# Git prompt
Invoke-SafeInstallModule posh-git 1
Import-Module posh-git

Invoke-SafeSetItem 'env:OS_ID' (($IsWindows) ? 'windows' : (($IsMacOS) ? 'macos' : (Get-Content '/etc/os-release' | Select-String '^ID=').Line.Split('=')[1]))

function charHost {
    if ($env:OS_ID -eq 'windows') { [char]0xf17a }
    elseif ($env:OS_ID -eq 'macos') { [char]0xf179 }
    elseif ($env:OS_ID -eq 'arch') { [char]0xf303 }
    elseif ($env:OS_ID -eq 'debian') { [char]0xf306 }
    elseif ($env:OS_ID -eq 'raspios') { [char]0xf315 }
    else { [char]0xf17c }
}
function charUser {
    if ($env:USERNAME -eq 'root' -or
        $env:USERNAME -eq 'admin'
    ) { [char]0xf0f0 }
    elseif ($env:USERNAME -eq 'marshall' -or
        $env:USERNAME -eq 'meop' -or
        $env:USERNAME -eq 'meoporter' -or
        $env:USERNAME -eq 'mporter'
    ) { [char]0xf007 }
    else { [char]0xf21b }
}
function charFolder {
    [char]0xf07c
}
function charPrompt {
    [char]0xf061
}
function charShell {
    [char]0xf1d1
}

# single quotes matters.. it prevents shell
# from evaluating the params at time of dot sourcing

# custom prompt
$script:PWSH_COLOR_CYAN = "`e[36m"
$script:PWSH_COLOR_MAGENTA = "`e[35m"
$script:PWSH_COLOR_WHITE = "`e[37m"
$script:PWSH_COLOR_YELLOW = "`e[33m"

$script:PWSH_COLOR_BLUE = "`e[34m"

$script:PWSH_COLOR_RESET = "`e[0m"

# $GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::DarkYellow
# $GitPromptSettings.DefaultPromptPrefix.Text = ''
$GitPromptSettings.DefaultPromptPrefix = ' $PWSH_COLOR_CYAN$(charHost) $env:HOSTNAME $PWSH_COLOR_MAGENTA$(charUser) $env:USERNAME $PWSH_COLOR_WHITE$(charShell) pwsh $PWSH_COLOR_YELLOW$(charFolder) $PWSH_COLOR_RESET'
$GitPromptSettings.DefaultPromptPath.ForegroundColor = [ConsoleColor]::DarkYellow
# $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkCyan
# $GitPromptSettings.DefaultPromptSuffix.Text = ''
$GitPromptSettings.DefaultPromptSuffix = ' $PWSH_COLOR_BLUE$(charPrompt) $PWSH_COLOR_RESET'

$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $false
$GitPromptSettings.DefaultPromptBeforeSuffix = '`n'

# Git status
$GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::Blue
$GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::Blue
