enum QemuAudioOption {
    None
    PulseHda
    SpiceHda
}

enum QemuDisplayOption {
    None
    GtkStd
    # note: gtk renderer currently has 30hz max:
    # https://github.com/intel/gvt-linux/issues/35
    GtkGvtAttachPciMdevPartition
    SpiceQxl
    # note: trying to fullscreen
    # or with nvidia dma-buf in host
    # will both hard fail:
    # https://gitlab.freedesktop.org/spice/spice-gtk/issues/100
    SpiceGvtAttachPciMdevPartition
    AttachPciGpuController
}

enum QemuSerialOption {
    None
    XhciUsb
    XhciUsbAttachHostDevices
    SpiceUsbRedirDevices
    AttachPciUsbController
}

enum QemuCheck {
    dmesg
    iommu
    pci_reset
    usb
}

function Invoke-QemuCheck (
    [Parameter(Mandatory = $true)] [QemuCheck] $CheckScript
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $line = "bash $PSScriptRoot/scripts/$CheckScript.sh"

    Invoke-LineAsCommandOnConsoleAsRoot `
        -Line $line `
        -WhatIf:$WhatIf `
        -Config $Config
}

function Invoke-Qemu (
    [Parameter(Mandatory = $true)] [string] $Name
    , [Parameter(Mandatory = $false)] [int] $Cores
    , [Parameter(Mandatory = $false)] [string] $Memory
    , [Parameter(Mandatory = $false)] [QemuAudioOption] $AudioOption = [QemuAudioOption]::None
    , [Parameter(Mandatory = $false)] [QemuDisplayOption] $GraphicsOption = [QemuDisplayOption]::None
    , [Parameter(Mandatory = $false)] [QemuSerialOption] $SerialOption = [QemuSerialOption]::None
    , [Parameter(Mandatory = $false)] [switch] $WhatIf
    , [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    $machineConfigFilePath = Get-QemuMachineArgsPath $Name.ToLowerInvariant()
    if (-not (Test-Path $machineConfigFilePath)) {
        Write-Host "machine name '$Name' has no config file.."
        return
    }

    . $machineConfigFilePath

    $c = $Config['qemu']
    $machinesDir = $c['machinesDir']

    $pciBoardId = $c['pci']['boardId']
    $pciIds = $c['pci']['ids']

    $pciIdIgd = $pciIds['integratedGrapicsDevice']
    $pciIdUsbCtrl = $pciIds['usbController']

    $Cores = $Cores ? $Cores : $c['default']['cores']
    $Memory = $Memory ? $Memory : $c['default']['memory']

    $qemuArgs = @()
    $audioExport = @()

    $qemuArgs += $(args_machine $Cores $Memory $machinesDir)
    $qemuArgs += $(args_network $c['netdev']['bridge'])
    $qemuArgs += $(args_disks $c['disksDir'] $c['isosDir'])

    switch ($AudioOption) {
        ([QemuAudioOption]::SpiceHda) {
            $audioExport = @(
                , 'QEMU_AUDIO_DRV=spice'
            )
            $qemuArgs += $(args_audio_hda)
        }
        ([QemuAudioOption]::PulseHda) {
            $audioExport = @(
                , 'QEMU_AUDIO_DRV=pa'
                , 'QEMU_PA_SERVER=/run/user/1000/pulse/native'
            )
            $qemuArgs += $(args_audio_hda)
        }
        Default {
            $audioExport = @(
                , ''
            )
        }
    }

    $vfioResetGvtMdevPartition = $false
    $gvtUuid = ''

    switch ($GraphicsOption) {
        ([QemuDisplayOption]::AttachPciGpuController) {
            $qemuArgs += $(args_gpu_vfio $pciIds['gpuMultifunction'] $pciIds['gpuAudio'])
        }
        ([QemuDisplayOption]::SpiceGvtAttachPciMdevPartition) {
            $vfioResetGvtMdevPartition = $true
            $gvtUuid = $(uuidgen)
            $qemuArgs += $(args_gpu_spice_gvtg $machinesDir $pciBoardId $pciIdIgd $gvtUuid)
        }
        ([QemuDisplayOption]::SpiceQxl) {
            $qemuArgs += $(args_gpu_spice)
        }
        ([QemuDisplayOption]::GtkGvtAttachPciMdevPartition) {
            $vfioResetGvtMdevPartition = $true
            $gvtUuid = $(uuidgen)
            $qemuArgs += $(args_gpu_gtk_gvtg $machinesDir $pciBoardId $pciIdIgd $gvtUuid)
        }
        ([QemuDisplayOption]::GtkStd) {
            $qemuArgs += $(args_gpu_gtk)
        }
        Default {
            $qemuArgs += $(args_gpu_none)
        }
    }

    $vfioResetUsbController = $false
    switch ($SerialOption) {
        ([QemuSerialOption]::AttachPciUsbController) {
            $vfioResetUsbController = $true
            $qemuArgs += $(args_usb_vfio $pciIdUsbCtrl)
        }
        ([QemuSerialOption]::SpiceUsbRedirDevices) {
            $qemuArgs += $(args_usb_spice $c['spice']['usbCount'])
        }
        ([QemuSerialOption]::XhciUsbAttachHostDevices) {
            $qemuArgs += $(args_usb_passthru $c['usb']['sets'])
        }
        ([QemuSerialOption]::XhciUsb) {
            $qemuArgs += $(args_usb_xhci)
        }
        Default {
        }
    }

    function SeparateCmds ($Line) {
        ($Line -join " ;`n") + " ;`n"
    }

    function SeparateArgs ($Line) {
        ($Line -join " \`n") + " ;`n"
    }

    $line = ''

    if ($vfioResetGvtMdevPartition) {
        $line += SeparateCmds (
            Set-QemuPreCmdCreateVGpu $gvtUuid $c['gvtg']['type'] $pciIdIgd
        )
    }

    if ($vfioResetUsbController) {
        $line += SeparateCmds (
            Set-QemuPreCmdRebindPciDeviceToDriver $pciIdUsbCtrl
        )
    }

    $exePath = @( $c['exePath'] )
    $line += SeparateArgs (
        $audioExport += $exePath += $qemuArgs
    )

    if ($vfioResetGvtMdevPartition) {
        $line += SeparateCmds (
            Set-QemuPostCmdRemoveVGpu $gvtUuid $pciIdIgd
        )
    }

    if ($vfioResetUsbController) {
        $line += SeparateCmds (
            Set-QemuPostCmdResetPciDeviceDriver $pciIdUsbCtrl
        )
    }

    Invoke-LineAsCommandOnConsoleAsRoot `
        -Line $Line `
        -WhatIf:$WhatIf `
        -Config $Config
}