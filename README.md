# Overview

Powershell profile with some useful functions

## Prerequisite

Install PowerShell Core

<https://github.com/PowerShell/PowerShell>

## Setup

Clone this project to the PowerShell Core profile directory

Note: If you already have files there that you want to keep, this project can instead be cloned into a sub folder there and you can swap between profiles, but that is outside the scope of this documentation

### Windows

\%userprofile%\Documents\PowerShell\

### Linux

./config/powershell

## Config

Copy the example config and edit as desired

> pseudo: cp ./config.example.yml ./config.yml

## Initializers

This is a place to include files to dot source, ie. load other modules on the system

A few examples are provided, ie.:

> pseudo: cp ./Initializers.example/modules.ps1 ./Initializers/modules.ps1

### [Optional] Use included prompt

Copy the example prompt and edit as desired

> pseudo: cp ./Initializers.example/prompt.ps1 ./Initializers/prompt.ps1

### Colors

<https://github.com/microsoft/terminal/tree/master/src/tools/ColorTool>

ColorTool -x -b prompt-colors.ini
