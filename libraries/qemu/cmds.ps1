function Set-QemuPreCmdCreateVGpu (
    [Parameter(Mandatory = $true)] [string] $GvtGuid
    , [Parameter(Mandatory = $true)] [string] $GvtType
    , [Parameter(Mandatory = $true)] [string] $BusId
    , [Parameter(Mandatory = $false)] [string] $BoardId = '0000'
) {
    $fullBusId = $BoardId + ':' + $BusId
    @(
        , "echo $GvtGuid > /sys/bus/pci/devices/$fullBusId/mdev_supported_types/$GvtType/create"
    )
}

function Set-QemuPostCmdRemoveVGpu (
    [Parameter(Mandatory = $true)] [string] $GvtGuid
    , [Parameter(Mandatory = $true)] [string] $BusId
    , [Parameter(Mandatory = $false)] [string] $BoardId = '0000'
) {
    $fullBusId = $BoardId + ':' + $BusId
    @(
        , "echo 1 > /sys/bus/pci/devices/$fullBusId/$GvtGuid/remove"
    )
}

function Set-QemuPreCmdRebindPciDeviceToDriver (
    [Parameter(Mandatory = $true)] [string] $BusId
    , [Parameter(Mandatory = $false)] [string] $BoardId = '0000'
    , [Parameter(Mandatory = $false)] [string] $Driver = 'vfio-pci'
) {
    $fullBusId = $BoardId + ':' + $BusId
    @(
        , "echo $Driver > /sys/bus/pci/devices/$fullBusId/driver_override"
        , "echo $fullBusId > /sys/bus/pci/devices/$fullBusId/driver/unbind"
        , "echo $fullBusId > /sys/bus/pci/drivers/$Driver/bind"
        , "echo > /sys/bus/pci/devices/$fullBusId/driver_override"
    )
}

function Set-QemuPostCmdResetPciDeviceDriver (
    [Parameter(Mandatory = $true)] [string] $BusId
    , [Parameter(Mandatory = $false)] [string] $BoardId = '0000'
) {
    $fullBusId = $BoardId + ':' + $BusId
    @(
        , "echo $fullBusId > /sys/bus/pci/devices/$fullBusId/driver/unbind"
        , "echo $fullBusId > /sys/bus/pci/drivers_probe"
    )
}