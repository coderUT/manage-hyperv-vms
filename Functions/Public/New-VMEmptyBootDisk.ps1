enum BootDiskType { 
	Dynamic 
	Fixed 
}
function New-VMEmptyBootDisk {
	<#
		.SYNOPSIS
		Create a Generation 2 VM with an empty boot disk

		.DESCRIPTION
		Create a Generation 2 VM with empty boot disk (SCSI Controller 0, Location 1). Requires
		Hyper-V Powershell management cmdlets and permissions to manage VMs on the host.

		The VM Configuration is:
		1 Processor, 1 SCSI Controller, 1 DVD Drive, 1 empty Boot VHD, Checkpoints off,
		all Integration Services enabled, Automatic Stop Action is set to Save, Automatic
		Start Action is set to Nothing

		.PARAMETER Name
		Name of the Hyper-V VM to create

		.PARAMETER Path
		Path where VM boot VHD will be located. VM Boot disk will be named: <Path>\<VMName>_boot.vhdx

		.PARAMETER Version
		Hyper-V VM Version. This value cannnot be downgraded after a VM is created,
		defaults to the default version for the host where this script is run

		.PARAMETER BootDiskSize
		Path to an existing VHD template to be copied for the VM boot disk (current limit is 2TB),
		Minimum value is 32MB (from some cursory research, it appears that the smallest Linux distros
		are currently 16MB, so this leaves some space for growth), Default value is 128GB, similar to Azure VMs
		
		.PARAMETER BootDiskType
		Should the Boot Disk be a Dynamic or Fixed VHDx, default is a Dynamic VHDx
		
		.PARAMETER DvdISOPath
		Use this optional parameter to load the Dvd drive with a OS disk image so that installation
		can begin on first VM boot

		.PARAMETER NetworkAdapters
		VM defaults to no network adapter, specify a total number of adapters or 0 for no adapters

		.PARAMETER Memory
		Amount of static memory (256MB or greater) to assign to the VM

		.PARAMETER MinimumMemory
		Set the minimum memory (256MB or greater) for the VM if using dynamic memory

		.PARAMETER MaximumMemory
		Set the maximum memory for the VM if using dynamic memory. Must be greater than
		minimum memory

		.PARAMETER StartupMemory
		Set the startup memory for a VM is using dynamic memory. Must be greater
		than or equal to minimum memory and less than or equal to maximum memory
		
		.EXAMPLE
		New-VMEmptyBootDisk -Name testVM -Path .\VHDs -Memory 1024MB -BootDiskSize 32MB

		Creates a VM named testVM with 0 network adapters at the host default version, using static memory
		configuration of 1024MB and a dynamic VHDX of 32 MB (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1)

		.EXAMPLE
		New-VMEmptyBootDisk -Name testVM -Path .\VHDs -Memory 1024MB -NetworkAdapters 2 -DvdISOPath .\test.iso

		Creates a VM named testVM with 2 network adapters (Ethernet1 and Ethernet2), using static memory
		configuration of 1024MB, a dynamic VHDX of 128GB (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1)
		and the ISO .\test.iso loaded in the DVD drive

		.EXAMPLE
		New-VMEmptyBootDisk -Name testVM -Path .\VHDs -MinimumMemory 256MB -MaximumMemory 1024MB -StartupMemory 512MB -NetworkAdapters 2

		Creates a VM named testVM with 2 network adapters (Ethernet1 and Ethernet2), using dynamic memory with startup
		memory of 512MB, minimum memory of 256MB, maximum memory of 1024MB, and a dynamic VHDX of 128GB
		(.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1)

		.LINK
		https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMEmptyBootDisk.md
	#>

	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory=$true, HelpMessage="New VM Name", ParameterSetName="SetVMFixedMemory", Position=0)]
		[Parameter(Mandatory=$true, HelpMessage="New VM Name", ParameterSetName="SetVMDynamicMemory", Position=0)]
		[ValidateNotNullOrEmpty()]
		[string] $Name,

		[Parameter(Mandatory=$true, HelpMessage="Set VM Boot VHD Path", ParameterSetName="SetVMFixedMemory", Position=1)]
		[Parameter(Mandatory=$true, HelpMessage="Set VM Boot VHD Path", ParameterSetName="SetVMDynamicMemory", Position=1)]
		[ValidateScript({
			if(Test-Path $_ -PathType Container) { $true; }
			else {
				Throw("Specified value must be an existing folder");
			}
		})]
		[string] $Path,

		[Parameter(Mandatory=$false, HelpMessage="New VM Version", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="New VM Version", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if($_ -in [string[]](Get-VMHostSupportedVersion | select -Property Version | ForEach {$_.Version.ToString()})) { $true; }
			else {
				Throw("Specified value: {0}, is not valid on this Host" -f $_);
			}
		})]
		[string] $Version = ((Get-VMHostSupportedVersion | where {$_.IsDefault -eq $true} | select -Property Version).Version.ToString()),

		[Parameter(Mandatory=$false, HelpMessage="Empty Boot Disk Size", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="Empty Boot Disk Size", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if(($_ -ge 32MB) -and ($_ -le 2048GB)) { $true; }
			else {
				Throw("Boot disk size must be between 32MB and 2048GB");
			}
		})]
		[Int64] 
		$BootDiskSize = 128GB,

		[Parameter(Mandatory=$false, HelpMessage="Empty Boot Type", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="Empty Boot Type", ParameterSetName="SetVMDynamicMemory")]
		[BootDiskType] $BootDiskType = [BootDiskType]::Dynamic,

		[Parameter(Mandatory=$false, HelpMessage="Set Path to an ISO file for the VM Dvd", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="Set Path to an ISO file for the VM Dvd", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if(Test-Path $_ -PathType Leaf) { $true; }
			else {
				Throw("Specified value must refer to an existing ISO file");
			}

			if($_.EndsWith(".ISO", $true, $PSCulture)) { $true; }
			else {
				Throw("Specified value must point to an existing ISO file");
			}
		})]
		[string] $DvdISOPath = "",

		[Parameter(Mandatory=$false, HelpMessage="Specify Number of Network Adapters for the VM", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="Specify Number of Network Adapters for the VM", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if($_ -ge 0) { $true; }
			else {
				Throw("Specified value must be 0 or higher");
			}
		})]
		[int] $NetworkAdapters = 0,

		[Parameter(Mandatory=$true, HelpMessage="Set VM Memory", ParameterSetName="SetVMFixedMemory")]
		[ValidateScript({
			if($_ -ge 256MB) { $true; }
			else {
				Throw("Specified value must be at least 256MB");
			}
		})]
		[int64] $Memory = -1,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Minimum Memory", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if($_ -ge 256MB) { $true; }
			else {
				Throw("Specified value must be at least 256MB")
			}
		})]
		[int64] $MinimumMemory = -1,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Maximum Memory", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if($_ -ge 256MB) { $true; }
			else {
				Throw("Specified value must be at least 256MB")
			}
		})]
		[int64] $MaximumMemory = -1,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Startup Memory", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if($_ -ge 256MB) { $true; }
			else {
				Throw("Specified value must be at least 256MB")
			}
		})]
		[int64] $StartupMemory = -1
	)

	process {
		#Check if there is already file in the Path where the Boot VHDx will be placed
		$BootVHD = Join-Path -Path $Path -ChildPath ($Name + "_boot.vhdx");
		If(Test-Path $BootVHD) {
			Throw ("Boot VHDx: {0}, exists, change the VM name" -f $BootVHD);
		}

		Write-Verbose ("Starting Create VM: {0}, Version: {1}, Network Adapters: {2}" -f $Name, $Version, $NetworkAdapters);
		$NewVMParams = @{
			Name=$Name;
			Version=$Version;
			NetworkAdapters=$NetworkAdapters;
			Memory=$Memory;
			MinimumMemory=$MinimumMemory;
			MaximumMemory=$MaximumMemory;
			StartupMemory=$StartupMemory;
		}
		
		If($PSBoundParameters['Verbose']) { 
			$UseVerbose = $true;
			$NewVMParams.Add('Verbose', $true);
		}

		If($PSBoundParameters['Debug']) { 
			$NewVMParams.Add('Debug', $true);
			$DebugPreference = 'Continue';
			Foreach($Key in $NewVMParams.Keys) {
				Write-Debug ("New VM Param: {0}={1}" -f $Key, $NewVMParams[$Key]);
			}
		}
		
		$WorkingVM = Run-NewVMTaskInternal @newVMParams;

		if($WorkingVM -ne $null) {
			If($BootDiskType -eq [BootDiskType]::Fixed) {
				New-VHD -Path $BootVHD -Fixed -SizeBytes $BootDiskSize | Out-Null;
				Write-Verbose ("Create Boot Disk as Fixed VHDx: {0}" -f $BootVHD);
			} else {
				New-VHD -Path $BootVHD -Dynamic -SizeBytes $BootDiskSize | Out-Null;
				Write-Verbose ("Create Boot Disk as Dynamic VHDx: {0}" -f $BootVHD);
			}

			Add-VMHardDiskDrive -VM $WorkingVM -ControllerType SCSI -ControllerNumber 0 -Path $BootVHD;
			Write-Verbose ("Attached Boot Disk to VM: {0}, SCSI Controller 0" -f $Name);

			if(-not [string]::IsNullOrEmpty($DvdISOPath)) {
				Set-VMDvdDrive -VMName $WorkingVM.Name -Path $DvdISOPath;
				Write-Verbose ("Set VM Dvd Drive to: {0}" -f $DvdISOPath)
			}
		}
	}
}
