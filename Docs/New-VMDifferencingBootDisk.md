---
external help file: manage-hyperv-vms-help.xml
Module Name: manage-hyperv-vms
online version: https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMDifferencingBootDisk.md
schema: 2.0.0
---

# New-VMDifferencingBootDisk

## SYNOPSIS
Create a Generation 2 VM for a VHD template (generalized VM) using a differencing disk

## SYNTAX

### SetVMDynamicMemory
```
New-VMDifferencingBootDisk [-Name] <String> [-Path] <String> [-Version <String>] [-ParentDiskPath] <String>
 [-NetworkAdapters <Int32>] -MinimumMemory <Int64> -MaximumMemory <Int64> -StartupMemory <Int64>
 [<CommonParameters>]
```

### SetVMFixedMemory
```
New-VMDifferencingBootDisk [-Name] <String> [-Path] <String> [-Version <String>] [-ParentDiskPath] <String>
 [-NetworkAdapters <Int32>] -Memory <Int64> [<CommonParameters>]
```

## DESCRIPTION
Create a Generation 2 VM where the boot disk (SCSI Controller 0, Location 1) is created as 
a differencing disk, and the the parent disk is the VHD template.
Requires Hyper-V Powershell
management cmdlets and permissions to manage VMs on the host.

The VM Configuration is:
1 Processor, 1 SCSI Controller, 1 DVD Drive, 1 differencing Boot VHD, Checkpoints off,
all Integration Services enabled, Automatic Stop Action is set to Save, Automatic
Start Action is set to Nothing

## EXAMPLES

### EXAMPLE 1
```
New-VMDifferencingBootDisk -Name testVM -Path .\VHDs -ParentDiskPath .\VHDs\vhdtemplate.vhdx -Memory 1024MB
```

Creates a VM named testVM with 0 network adapters at the host default version, using static memory
configuration of 1024MB and VHDx (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1) that is a differencing
disk with a parent disk of .\VHDs\vhdtemplate.vhdx

### EXAMPLE 2
```
New-VMDifferencingBootDisk -Name testVM -Path .\VHDs -ParentDiskPath .\VHDs\vhdtemplate.vhdx -NetworkAdapters 2 -Memory 1024MB
```

Creates a VM named testVM with 2 network adapters (Ethernet1 and Ethernet2) at the host default version, using static memory
configuration of 1024MB and VHDx (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1) that is a differencing
disk with a parent disk of .\VHDs\vhdtemplate.vhdx

### EXAMPLE 3
```
New-VMDifferencingBootDisk -Name testVM -Path .\VHDs -ParentDiskPath .\VHDs\vhdtemplate.vhdx -StartupMemory 512MB -MinimumMemory 256MB -MaximumMemory 1024MB
```

Creates a VM named testVM with 0 network adapters at the host default version, using dynamic memory with statup memory of 512MB
minimum memory of 256MB and maximum memory of 1024MB and VHDx (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1) that is a
differencing disk with a parent disk of .\VHDs\vhdtemplate.vhdx

## PARAMETERS

### -Name
Name of the Hyper-V VM to create

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path where VM boot VHD will be located.
VM Boot disk will be named: \<Path\>\\\<VMName\>_boot.vhdx

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
Hyper-V VM Version.
This value cannnot be downgraded after a VM is created,
defaults to the default version for the host where this script is run

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ((Get-VMHostSupportedVersion | where {$_.IsDefault -eq $true} | select -Property Version).Version.ToString())
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentDiskPath
Path to an existing VHD template to be used as a parent for the boot differencing disk

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkAdapters
VM defaults to no network adapter, specify a total number of adapters or 0 for no adapters

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Memory
Amount of static memory (256MB or greater) to assign to the VM

```yaml
Type: Int64
Parameter Sets: SetVMFixedMemory
Aliases:

Required: True
Position: Named
Default value: -1
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumMemory
Set the minimum memory (256MB or greater) for the VM if using dynamic memory

```yaml
Type: Int64
Parameter Sets: SetVMDynamicMemory
Aliases:

Required: True
Position: Named
Default value: -1
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumMemory
Set the maximum memory for the VM if using dynamic memory.
Must be greater than
minimum memory

```yaml
Type: Int64
Parameter Sets: SetVMDynamicMemory
Aliases:

Required: True
Position: Named
Default value: -1
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartupMemory
Set the startup memory for a VM is using dynamic memory.
Must be greater
than or equal to minimum memory and less than or equal to maximum memory

```yaml
Type: Int64
Parameter Sets: SetVMDynamicMemory
Aliases:

Required: True
Position: Named
Default value: -1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMDifferencingBootDisk.md](https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMDifferencingBootDisk.md)

