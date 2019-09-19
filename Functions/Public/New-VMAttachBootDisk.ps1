function New-VMAttachBootDisk {
	<#
		.SYNOPSIS
		Create a Generation 2 VM and attach an existing disk (it should be a boot disk or a VHD template)

		.DESCRIPTION
		Create a Generation 2 VM and attach an existing VHD to SCSI Controller 0, Location 1
		It could be a bootable disk or a VHD template or not. Can optionally attach no disk.
		Requires Hyper-V Powershell management cmdlets and permissions to manage VMs on the host.

		The VM Configuration is:
		1 Processor, 1 SCSI Controller, 1 DVD Drive, 1 attached Boot VHD, Checkpoints off,
		all Integration Services enabled, Automatic Stop Action is set to Save, Automatic
		Start Action is set to Nothing

		.PARAMETER Name
		Name of the Hyper-V VM to create

		.PARAMETER Version
		Hyper-V VM Version. This value cannnot be downgraded after a VM is created,
		defaults to the default version for the host where this script is run

		.PARAMETER TargetDiskPath
		Path to an existing VHD to be attached to SCSI Controller 0, Location 1

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
		New-VMAttachBootDisk -Name testVM -MinimumMemory 256MB -MaximumMemory 1024MB -StartupMemory 256MB
		
		Creates a VM named testVM with no NetworkAdapters at the host default version, using dynamic memory with startup memory
		of 256MB, minimum memory of 256MB and maximum memory of 1024MB, no network adapters and no VHD's attached

		.EXAMPLE
		New-VMAttachBootDisk -Name testVM -NetworkAdapters 2 -Memory 1024MB

		Creates a VM named testVM with 2 network adapters (Ethernet1 and Ethernet2) at the host default version, using static memory
		configuration of 1024MB and no VHD's attached

		.EXAMPLE
		New-VMAttachBootDisk -Name testVM -Version 8.0 -NetworkAdapters 2 -Memory 1024MB -TargetDiskPath .\test.vhdx
		
		Creates a VM named testVM with 2 network adapters at version 8.0 (Server 2016 Host), using static memory configuration of
		1024MB and a VHD attached via a relative path @SCSI Controller 0, Location 1

		.LINK
		https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMAttachBootDisk.md
	#>

	[CmdletBinding(PositionalBinding=$false)]
	param (
		[Parameter(Mandatory=$true, HelpMessage="New VM Name", ParameterSetName="SetVMFixedMemory", Position=0)]
		[Parameter(Mandatory=$true, HelpMessage="New VM Name", ParameterSetName="SetVMDynamicMemory", Position=0)]
		[ValidateNotNullOrEmpty()]
		[string] $Name,

		[Parameter(Mandatory=$false, HelpMessage="New VM Version", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="New VM Version", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if($_ -in [string[]](Get-VMHostSupportedVersion | select -Property Version | ForEach {$_.Version.ToString()})) { $true; }
			else {
				Throw("Specified value: {0}, is not valid on this Host" -f $_);
			}
		})]
		[string] $Version = ((Get-VMHostSupportedVersion | where {$_.IsDefault -eq $true} | select -Property Version).Version.ToString()),

		[Parameter(Mandatory=$false, HelpMessage="Path to VHD to Attach", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="Path to VHD to Attach", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			if(Test-Path $_ -PathType Leaf) { $true; }
			else {
				Throw("Specified value must refer to an existing VHD");
			}
			
			if(($_.EndsWith(".VHD", $true, $PSCulture)) -or ($_.EndsWith(".VHDX", $true, $PSCulture))) { $true; }
			else {
				Throw("Specified value must point to an existing VHD or VHDx file");
			}
		})]
		[string] $TargetDiskPath,

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
			#We don't have to check the TargetDiskPath here as the path is a validated parameter
			if(-not [string]::IsNullOrEmpty($TargetDiskPath)) {
				Add-VMHardDiskDrive -VM $WorkingVM -ControllerType SCSI -ControllerNumber 0 -Path $TargetDiskPath;
				Write-Verbose ("Attached Disk to VM: {0}, SCSI Controller 0" -f (Resolve-Path -Path $TargetDiskPath).Path);
			}
		}
	}
}

