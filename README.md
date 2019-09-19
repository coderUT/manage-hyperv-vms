# manage-hyperv-vms
Collection of Value-Added Functions layered on top of the built-in Hyper-V cmdlets.

### Background

This module was inspired by the scripts I've been creating to setup VM enviroments for
learning Windows Server and Azure. As the scripts became overly complicated, it made more 
more sense to refactor them into distinct functions and create a module.

There is no defined "roadmap" for this module; it is more of a "add functions when a script
becomes to complicated and requires re-factoring.

### Version 1.0.0
The initial release of this module contains 4 public functions, all for creating VMs on 
a Windows host in various different configurations.

The general usage scenario would be creating a new
VM from a generalized VM/VHD template (using the VHD template directly as a boot disk, copying it or creating a
differencing disk pointed to it).

#### Create VM Functions, Common Features
* Single-Processor, Generation 2 VMs
* Memory Configurations
  * Static
  * Dynamic (Startup Memory, Minimum Memory and Maxium Memory)
* Integration Services
  *  All Services Enabled
     * Guest Service Interface
     * Heartbeat
     * Key-Value Pair Exchange
     * Shutdown
     * Time Synchronization
* Checkpoints are Disabled
* Automatic Actions
  * StartAction: Nothing
  * StopAction: Save
* VM Version
  * Defaults to the Host version (grabs all versions supported by the host, therefore privileges to
execute Get-VMHostSupportedVersion are required)
* Network Adapters
  * Defaults to no Adapters, but can have as many as required
* Virtual Dvd Drive  

#### 1 - New-VMAttachBootDisk Function
* [https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMAttachBootDisk.md](https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMAttachBootDisk.md)
* Valid Virtual Disk Configurations
  * No Disks attached
  * Existing VHD attached to SCSI Controller 0, Location 1

##### No Disks Attached, Static Memory
```powershell
PS C:\> New-VMAttachBootDisk -Name testVM -Memory 1024MB
```
##### No Disks Attached, Dynamic Memory
```powershell
PS C:\> New-VMAttachBootDisk -Name testVM -StartupMemory 512MB -MinimumMemory 256MB -MaximumMemory 1024MB
```
##### Attach Existing Disk, 2 Network Adapters
```powershell
PS C:\> New-VMAttachBootDisk -Name testVM -TargetDiskPath C:\test.vhdx -NetworkAdapters 2 -Memory 1024MB
```

#### 2 - New-VMEmptyBootDisk Function
* [https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMEmptyBootDisk.md](https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMEmptyBootDisk.md)
* Valid Virtual Disk Configurations (32MB to 2048GB, default size 128GB)
  * Creates Dynamic, Empty VHDx at specified size attached to SCSI Controller 0, Location 1
  * Creates Fixed, Empty VHDx at specified size attached to SCSI Controller 0, Location 1
  * New Boot Disk name is: **\<VM Name\>_boot.vhdx**
* Virtual Dvd Drive
  * Optionally load an ISO in the DvD drive
 
##### 64GB Dynamic Boot VHD
```powershell
PS C:\>New-VMEmptyBootDisk -Name testVM -Path .\VHDs -BootDiskSize 64GB -Memory 1024MB
```
##### 64GB Fixed Boot VHD, Dvd ISO Loaded
```powershell
PS C:\>New-VMEmptyBootDisk -Name testVM -Path .\VHDs -BootDiskSize 64GB -BootDiskType Fixed -Memory 1024MB -DvdISOPath .\text.iso
```

#### 3 - New-VMCopyBootDisk Function
* [https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMCopyBootDisk.md](https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMCopyBootDisk.md)
* Valid Virtual Disk Configuration
  * Copy an existing VHD/VHDx and attach it to SCSI Controller 0, Location 1
  * New Boot Disk name is: **\<VM Name\>_boot.vhdx**

##### Copy existing VHD
```powershell
PS C:\>New-VMCopyBootDisk -Name testVM -Path .\VHDs -TemplateDiskPath .\VHDs\template.vhdx -Memory 1024MB
```

#### 4 - New-VMDifferencingBootDisk Function
* [https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMDifferencingBootDisk.md](https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMDifferencingBootDisk.md)
* Valid Virtual Disk Configuration
  * Create a new VHD differncing disk with an existing VHD as its parent and attach it to SCSI Controller 0, Location 1
  * New Boot Disk name is: **\<VM Name\>_boot.vhdx**
```powershell
PS: C:\>New-VMDifferencingBootDisk -Name textVM -Path .\VHDs -ParentDiskPath .\VHDs\template.vhdx -Memory 1024MB
```
