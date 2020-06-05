# Setting up

## Install PowerShell Core

https://github.com/PowerShell/PowerShell

## Clone this project to the PowerShell profile directory

Note: If you already have files there that you want to keep, this project can instead be cloned into a sub folder there and you can swap between profiles, but that is outside the scope of this documentation

### Locations

#### Windows

\%userprofile%\Documents\PowerShell\

##### Linux

./config/powershell

## Copy prompt

If you want to use the provided prompt, or want to modify, or create your own.. you can then copy it into ./Initializers

> pseudo: cp ./prompt.ps1 ./Initializers/prompt.ps1