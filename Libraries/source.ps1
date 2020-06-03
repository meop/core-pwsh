Get-ChildItem -Path $PSScriptRoot -Include '*.ps1' -Exclude 'source.ps1' -Recurse -Depth 1 |
ForEach-Object { . $_.FullName }