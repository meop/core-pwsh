function Get-QemuMachineArgsPath (
    [Parameter(Mandatory = $true)] [string] $Name
) {
    "$global:PROFILE_ASSETS_DIR/qemu/machine-args/$Name.ps1"
}