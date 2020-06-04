function Get-DockerContainerImage (
    [Parameter(Mandatory = $true)] [string] $ContainerName
) {
    $containerName = $ContainerName.ToLowerInvariant()

    Import-AssetCsv `
        -Path "$global:PROFILE_ASSETS_DIR/docker/containers.csv" |
    Where-Object { $containerName -eq $_.Name.ToLowerInvariant() } |
    Select-Object -First 1
}

function Get-DockerContainerArguments (
    [Parameter(Mandatory = $true)] [string] $ContainerName
) {
    $containerName = $ContainerName.ToLowerInvariant()

    $path = "$global:PROFILE_ASSETS_DIR/docker/container-args/$containerName.ps1"
    if (Test-Path $path) {
        . $path
        $script:arguments -join ' '
    } else {
        $null
    }
}