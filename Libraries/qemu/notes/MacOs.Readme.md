https://www.insanelymac.com/forum/topic/329828-making-a-bootable-high-sierra-usb-installer-entirely-from-scratch-in-windows-or-linux-mint-without-access-to-mac-or-app-store-installerapp/

Browse for:

1. BaseSystem.dmg
2. BaseSystem.chunklist
3. InstallInfo.plist
4. InstallESDDmg.pkg
5. AppleDiagnostics.dmg
6. AppleDiagnostics.chunklist

http://swcdn.apple.com/content/downloads/49/44/041-08708/vtip954dc6zbkpdv16iw18jmilcqdt8uot/BaseSystem.dmg
http://swcdn.apple.com/content/downloads/49/44/041-08708/vtip954dc6zbkpdv16iw18jmilcqdt8uot/BaseSystem.chunklist
http://swcdn.apple.com/content/downloads/49/44/041-08708/vtip954dc6zbkpdv16iw18jmilcqdt8uot/InstallInfo.plist
http://swcdn.apple.com/content/downloads/49/44/041-08708/vtip954dc6zbkpdv16iw18jmilcqdt8uot/InstallESDDmg.pkg
http://swcdn.apple.com/content/downloads/49/44/041-08708/vtip954dc6zbkpdv16iw18jmilcqdt8uot/AppleDiagnostics.dmg
http://swcdn.apple.com/content/downloads/49/44/041-08708/vtip954dc6zbkpdv16iw18jmilcqdt8uot/AppleDiagnostics.chunklist

Rename InstallESDDmg.pkg to InstallESD.dmg

Edit InstallInfo.plist with WordPad/text editor to remove the chunklistURL and chunklistid keys for InstallESD, and renaming it from InstallESDDmg.pkg to InstallESD.dmg (example of edited file attached to this post)...

Use Qemu to create a raw image file, large enough to hold Clover and 4.hfs base install files.. which for Mojave are just < 2GB
    > qemu-img create -f raw disk.img 4G
Mount it as a usb-storage in Qemu Windows VM
    -device usb-storage,drive=osx-install \
    -blockdev raw,node-name=osx-install,file.driver=file,file.filename=/mnt/software/os/macos/osx_install_10.14.raw \

Follow the guide's directions for using the BDU tool

Edit the default Clover config.plist to set ScreenResolution to 1024x768.. to match OSX Base Image, so you can see its text output
    EFI/CLOVER
        config.plist
            ScreenResolution
                1024x768

Change the default drivers to be these:
    EFI/CLOVER/drivers64UEFI
        ApfsDriverLoader-64.efi
        AptioMemoryFix-64.efi
        DataHubDxe-64.efi
        FSInject-64.efi
        PartitionDxe-64.efi
        SMCHelper-64.efi
        VBoxHfs-64.efi

https://www.nicksherlock.com/2018/04/patch-ovmf-to-support-macos-in-proxmox-5-1/

Use a patched version of OVMF, that reverts the hardening commits that make the EFI page table read-only, because the memory fix drivers remap low to high memory like AptioUEFI boards expect (many PC types), and Clover passes through some of this to the parent EFI firmware, in this case OVMF

**Why not just use SeaBIOS + CloverEFI, instead of OVMF + CloverEFI?
    1. It would make MacOS differ from the Windows and Linux definitions.. even though they could technically also use SeaBIOS and CloverEFI, this is another layer to maintain just for MacOS
    2. BIOS VGA arbitration is painful.. would require lots of other legacy flags and methods in Qemu to pass through a PCIe GPU.. UEFI can just load the VGA card like any other PCI device
    3. Eventually BIOS will go away anyway..
    4. Hopefully a new driver / method that will allow MacOS to boot on Hackintosh AptioEFI style PCs will come about in the future, that does not manipulate the EFI memory pages, making maintaining a patched OVMF a thing of the past

Install kexts for:
    FakeSMC.kext - needed always
    AppleIntelE1000e.kext - for the Intel e1000e 82574L Qemu uses
    QemuUSBTablet1011.kext - for the usb-tablet Qemu uses

    ?? USBInjectAll.kext - needed for enabling all the USB ports

    ?? GenericUSBXHCI.kext - for 3rd party USB controllers, like the Asmedia PCI attach

Mount the raw image file as a ide-hd in the Qemu MacOS VM.. since it seemed to have trouble with the usb-storage..
    -device ide-hd,drive=osx-install \
    -blockdev raw,node-name=osx-install,file.driver=file,file.filename=/mnt/software/os/macos/osx_install_10.14.raw \

Follow the guide for:
    partitioning the target disk
    mounting the SharedFolder content over smb
    copying the boot disk and smb content to target disk
    running install command on target disk, which reboots machine

    -bash-3.2# cd /
    -bash-3.2# cp -R Install\ macOS\ Mojave.app /Volumes/Macintosh\ HD/
    -bash-3.2# cp -R /Volumes/DATA/SharedSupport /Volumes/Macintosh\ HD/Install\ macOS\ Mojave.app/Contents/
    -bash-3.2# /Volumes/Macintosh\ HD/Install\ macOS\ Mojave.app/Contents/Resources/startosinstall --volume /Volumes/Macintosh\ HD

Boot the install disk again, this time select the target which should be in install mode

Let it install

After it installs, you can switch OVMF and CLOVER back to 1920x1080 resolution..

Install CLOVER directly to the target os disk

Use CLOVER Configurator to tweak things, like
    Add themes
    FixShutdown

You can edit config.plist directly to set the theme

Make sure a valid SMBios was created by CLOVER already.. it should have been.. defaults to an old iMac 14,2
