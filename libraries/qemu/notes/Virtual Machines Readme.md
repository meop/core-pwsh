# Virtual Machines

## Virtualizers

### KVM/Qemu (Linux hosts only)

KVM is a hypervisor built into the Linux kernel, so it is in between a Type-1 and Type-2 hypervisor.. best of both worlds.
Qemu is Type-2 hypervisor that can leverage KVM to provide advanced features like CPU acceleration and PCI passthrough.
Generally for more permanent types of VMS I prefer KVM/Qemu.

#### Choosing emulated harware

I generally stick will the idea of passing through as much as possible, starting with controllers down to devices.
But in the case where emulating makes more sense, like standalone audio controllers, or network controllers, choosing the best performing emulated hardware that *does not* require any 3rd party drivers is my preference.
Also I try to avoid differing hardware per guest operating system, because it easiest to maintain the guest operating systems if they are as vanilla as possible.
So even though there are virtio drivers for disk and network devices, they are not native to Linux or Windows, and are not supported in Macos, so I am not using them.
Also their performance benefits were shown in benchmarks to be only in certain use cases, and for my guests, disk and network activity is not being done all the time, so any negative performance should not be very noticeable from a user perspective.

#### Choosing emulated disk types

I try to keep the emulated disk matching the host disk. So SATA for SATA and NVME for NVME.
Note ?? One thing to remember for Windows guests is that, at least for SATA, it decides whether the disk is SSD or HDD based on performance metrics.
So if you choose an emulation type that yields slow performance on an SSD host, the Windows guest will still consider the disk to be a HDD and not apply trim on it.
Not sure if Windows will always treat NVME disks as SSD, regardless of performance, but if so that could be a workaround, but not a great one because the emulated disk could be slower if not matching the host way of actually writing blocks.
For me this has not been a problem though, because I have been able to ensure that the emualted SATA disk performace is acceptable on SATA hosts.

#### Choosing host hardware

I am currently using an Intel host CPU with a built in GPU, with two heterogenous discrete Nvidia GPUs attached.
The motherboard has two PCI USB controllers, one from Intel and one from Asmedia. Only the Asmedia controller supports PCI reset.
So with this setup, I can have the host OS running, and two guest OS running, all three with their own GPUs, simultaneously.
The host can also give the Asmedia USB controller to the primary guest, and take it back when it shuts down.
The host can expose its Realtek Audio controller using a PulseAudio sound server for the guests to use as well.
I have separate SSD and HDD pairs for multiple choices for the primary guest, but these will probably get consolidated as disks become faster and cheaper.

#### Choosing host disk file format

At first I was just using QCOW2, but I read a tip that RAW would be the most performance for the base disk.
Then, QCOW2 could be used for differencing disks on top of the RAW base, if desired. I have not set up any of my KVM/Qemu VMS like that though.
If I want to rollback VMS, I am generally using VirtualBox.

#### Setting up on Arch Linux

Recommend installing using Grub2 with UEFI on a small fat32 partition, and the rest of /boot on an ext4 (or btrfs if you feel adventurous) partition.. so can store a few large kernel images on a non-fat32 location.
This is because Grub2 is probably not going to grow much, so 100MiB fat32 for all the UEFI tools you need is fine, and / can just contain /boot and you don't need to worry about kernel sizes

Install these from AUR:

1. linux-vfio (patches for ACS Override to split IOMMU groups and use PCI express passthrough more selectively)
2. qemu-patched (adds fixes for Intel Audio emulation, command line args for CPU pinning, and some new GPU to GPU framebuffer copy thing which may be cool one day, if it does not need Guest OS mods)
3. ovmf

OVMF no longer supports Macos without either lots of changes to it to accomodate Macos or changes to the tools used to lie to Macos.. so Clover is needed instead of (or combined with, but since Clover can use Qemu built-in SeaBios, not really much point) it.
OVMF supports Linux and Windows, so I may just switch to it entirely if possible.

There are kernel boot params I use for the host Intel Skylake GPU

?? and special Grub2 configs are set..
?? there are lots of other /etc steps I do now

#### Compacting Qemu QCOW2 or RAW disks

These should have built in support, provided you turn on unmap and discard for the device definitions

### VirtualBox

Virtualbox is a pure Type-2 hypervisor. It has lots of emulation features that Qemu lacks, like DirectX support for Windows guests.
It is easy to set up lots of plug and play emulation, and it has a nice UI.
It also has all the features that the non-free VmWare Workstation has that I use.
Generally for less permanent types of VMS, or VMS inside of VMS, I prefer VirtualBox.

#### Choosing emulated disk types

I pretty much always use SATA.

#### Choosing host disk file format

VDI has generally been fine. It has some VirtualBox specific features vs VMDK, and it can be converted to other formats and exported to OMDF ?? as well.

#### Compacting VirtualBox VDI disks (Linux guests only)

Guest:

> dd if=/dev/zero of=zerofillfile bs=1M

Wait until out of space message:

> rm zerofillfile

Shutdown Guest.

Host:

> VBoxManage modifyhd --compact <vdiFile>

### Hyper-V

I believe that Hyper-V has the same hypervisor classification and advanced capabilities as KVM/Qemu, but they are limited to the non-free Windows Server edition.
For example, Windows Pro edition does not have PCI passthrough support.
But KVM/Qemu is free, so it is preferred.

# Operating Systems

## Linux

### Switching between KVM/Qemu and VirtualBox

KVM and VirtualBox both use Intel Vt-x for x64 machines, so cannot be running at the same time.

VirtualBox 5.x works on Linux by loading kernel modules, and these can be added or removed manually to avoid restarting when switching between KVM and VirtualBox:

To unload:

> rmmod vboxnetadp
> rmmod vboxnetflt
> rmmod vboxpci
> rmmod vboxdrv

To load:

> modprobe vboxdrv

I do not think it is needed to unload KVM to load VirtualBox, but the driver is this:

> rmmod kvm_intel
> rmmod kvm

> modprobe kvm

### Exposing physical disks to VirtualBox guests

Add user to groups ‘disk’, probably ‘wheel’ too

> VBoxManage internalcommands createrawvmdk -filename san.vmdk -rawdisk /dev/sda
> VBoxManage internalcommands createrawvmdk -filename wdc.vmdk -rawdisk /dev/sdc

## Windows

### Switching between Hyper-V and VirtualBox

Similarly, you cannot have 'Windows feature' Hyper-V installed and expect to VirtualBox.
But unlike Linux, I do not know a way to uninstall Hyper-V without a restart.

### Exposing physical disks to VirtualBox guests

You can see which disk is which using this command:

> Get-WmiObject Win32_DiskDrive

Then you can prep this disk using these steps:

1. close all open programs or documents on any partition on the disk to pass-through

2. open diskpart
> DISKPART

3. select hard drive carefully; disk numbering starts at zero:
> SELECT DISK <number>

4. (optional) verify you picked the right disk:
> LIST PARTITION
> LIST DISK

5. take disk offline and make writable:
> OFFLINE DISK
> DISK CLEAR READONLY

6. verify
> ATTRIBUTES DISK

7. exit diskpart ??

8. create vmdk, examples:
> & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' internalcommands createrawvmdk -filename ocz.vmdk -rawdisk \\.\PhysicalDrive1
> & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' internalcommands createrawvmdk -filename ste.vmdk -rawdisk \\.\PhysicalDrive3
