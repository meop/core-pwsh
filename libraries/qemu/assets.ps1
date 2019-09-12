function Get-QemuMachineArgsPath (
    [Parameter(Mandatory = $true)] [string] $Name
) {
    "$(Get-ProfileAssetsDir)/qemu/machine-args/$Name.ps1"
}