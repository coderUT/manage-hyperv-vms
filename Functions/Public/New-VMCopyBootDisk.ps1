function New-VMCopyBootDisk {
	<#
		.SYNOPSIS
		Create a Generation 2 VM for a VHD template (generalized VM) by copying the template disk

		.DESCRIPTION
		Create a Generation 2 VM where the boot disk (SCSI Controller 0, Location 1) is created as
		a copy of the VHD template disk. Requires Hyper-V Powershell management cmdlets and permissions
		to manage VMs on the host.

		The VM Configuration is:
		1 Processor, 1 SCSI Controller, 1 DVD Drive, 1 copied Boot VHD, Checkpoints off,
		all Integration Services enabled, Automatic Stop Action is set to Save, Automatic
		Start Action is set to Nothing

		.PARAMETER Name
		Name of the Hyper-V VM to create

		.PARAMETER Path
		Path where VM boot VHD will be located. VM Boot disk will be named: <Path>\<VMName>_boot.vhdx

		.PARAMETER Version
		Hyper-V VM Version. This value cannnot be downgraded after a VM is created,
		defaults to the default version for the host where this script is run

		.PARAMETER TemplateDiskPath
		Path to an existing VHD template to be copied for the VM boot disk

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
		New-VMCopyBootDisk -Name testVM -Path .\VHDs -TemplateDiskPath .\VHDs\vhdtemplate.vhdx -Memory 1024MB

		Creates a VM named testVM with 0 network adapters at the host default version, using static memory
		configuration of 1024MB and VHDx (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1) that is a copy
		of .\VHDs\vhdtemplate.vhdx
		
		.EXAMPLE
		New-VMCopyBootDisk -Name testVM -Path .\VHDs -TemplateDiskPath .\VHDs\vhdtemplate.vhdx -NetworkAdapters 2 -Memory 1024MB

		Creates a VM named testVM  with 2 network adapters at the host default version, using static memory
		configuration of 1024 MB and VHDx (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1) that is a copy
		of .\VHDs\vhdtemplate.vhdx

		.EXAMPLE
		New-VMCopyBootDisk -Name testVM -Path .\VHDs -TemplateDiskPath .\VHDs\vhdtemplate.vhdx -MinimumMemory 256MB -MaximumMemory 1024MB -StartupMemory 512MB

		Creates a VM named testVM with 0 network adapters at the host default version, using dynamic memory with statup memory of 512MB
		minimum memory of 256MB and maximum memory of 1024MB and VHDx (.\VHDs\testVM_boot.vhdx @SCSI Controller 0, Position 1) that is a copy
		of .\VHDs\vhdtemplate.vhdx

		.LINK
		https://github.com/coderUT/manage-hyperv-vms/blob/master/Docs/New-VMCopyBootDisk.md
	#>

	[CmdletBinding(PositionalBinding=$false)]
	Param (
		[Parameter(Mandatory=$true, HelpMessage="New VM Name", ParameterSetName="SetVMFixedMemory", Position=0)]
		[Parameter(Mandatory=$true, HelpMessage="New VM Name", ParameterSetName="SetVMDynamicMemory", Position=0)]
		[ValidateNotNullOrEmpty()]
		[string] $Name,

		[Parameter(Mandatory=$true, HelpMessage="Set VM Boot VHD Path", ParameterSetName="SetVMFixedMemory", Position=1)]
		[Parameter(Mandatory=$true, HelpMessage="Set VM Boot VHD Path", ParameterSetName="SetVMDynamicMemory", Position=1)]
		[ValidateScript({
			Test-Path $_ -PathType Container
		})]
		[string] $Path,

		[Parameter(Mandatory=$false, HelpMessage="New VM Version", ParameterSetName="SetVMFixedMemory")]
		[Parameter(Mandatory=$false, HelpMessage="New VM Version", ParameterSetName="SetVMDynamicMemory")]
		[ValidateScript({
			$_ -in [string[]](Get-VMHostSupportedVersion | select -Property Version | ForEach {$_.Version.ToString()})
		})]
		[string] $Version = ((Get-VMHostSupportedVersion | where {$_.IsDefault -eq $true} | select -Property Version).Version.ToString()),

		[Parameter(Mandatory=$true, HelpMessage="Template Disk Path", ParameterSetName="SetVMFixedMemory", Position=2)]
		[Parameter(Mandatory=$true, HelpMessage="Template Disk Path", ParameterSetName="SetVMDynamicMemory", Position=2)]
		[ValidateScript({
			Test-Path $_ -PathType Leaf
		})]
		[string] $TemplateDiskPath,

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
			Copy-Item -Path $TemplateDiskPath -Destination $BootVHD | Out-Null;
			Write-Verbose ("Create Boot Disk as VM Template Copy: {0} with Parent: {1}" -f $BootVHD, $TemplateDiskPath);

			Add-VMHardDiskDrive -VM $WorkingVM -ControllerType SCSI -ControllerNumber 0 -Path $BootVHD;
			Write-Verbose ("Attached Boot Disk to VM: {0}, SCSI Controller 0" -f $Name);
		}
	}
}
