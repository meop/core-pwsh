# https://github.com/PowerShell/Win32-OpenSSH/issues/518
# prevent scripts using ssh from blocking by prompting for passwords
# note: run ssh one time without this first so ssh can prompt and add your target to known hosts!
# or run ssh without strict user checking, but that is even less secure!

# note mporter: can be problematic
Invoke-SafeSetItem 'env:DISPLAY' 'localhost:0'
Invoke-SafeSetItem 'env:SSH_ASKPASS' "pwsh -NoProfile `"$($env:HOME)\Documents\Powershell\Bin\echopass.ps1`""