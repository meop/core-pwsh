$h = ($IsWindows) ? "$env:USERPROFILE" : "/home/$env:USER"
$d = "$h/.dotfiles/bin"
if (Test-Path $d) { Invoke-SafeAppendToPath $d }