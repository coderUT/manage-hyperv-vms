function New-VMInternal {
	<#
		.SYNOPSIS
		Create a Generation 2 VM

		.DESCRIPTION
		Create a Generation 2 VM with no boot disk and no memory specification. Requires Hyper-V Powershell
		management cmdlets and permissions to manage VMs.

		The VM Configuration is:
		1 Processor, 1 SCSI Controller, 1 DVD Drive, Checkpoints off,
		all Integration Services enabled, Automatic Stop Action is set to Save, Automatic
		Start Action is set to Nothing

		.PARAMETER Name
		Name of the Hyper-V VM to create

		.PARAMETER Version
		Hyper-V VM Version. This value cannnot be downgraded after a VM is created

		.PARAMETER NetworkAdapters
		Number of Network Adapters for the VM, default is 1, a value of zero is allowed
	#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true, HelpMessage="New VM Name")]
		[ValidateNotNullOrEmpty()]
		[string] $Name,

		[Parameter(Mandatory=$true, HelpMessage="New VM Version")]
		[ValidateScript({
			$_ -in [string[]](Get-VMHostSupportedVersion | select -Property Version | ForEach {$_.Version.ToString()})
		})]
		[string] $Version,

		[Parameter(Mandatory=$true, HelpMessage="Number of Network Adapters")]
		[ValidateScript({
			$_ -ge 0
		})]
		[int] $NetworkAdapters
	)

	process {
		#Check if the VM name is available
		If((Get-VM | where {$_.Name -eq $Name}) -ne $null) {
			Throw ("A VM with name: {0} already exists on the host" -f $Name);
		}

		#Create a new Generation 2 VM
		$WorkingVM = New-VM -Name $Name -Version $Version -NoVHD -Generation 2;
		Write-Verbose ("Created VM: {0}" -f $Name);

		#Configure the VM Stop/Start Actions and Disable Checkpoints
		$WorkingVM = ($WorkingVM | Set-VM -CheckpointType Disabled -AutomaticStopAction Save -AutomaticStartAction Nothing -Passthru);

		#Turn on all Guest Services
		$WorkingVM | Enable-VMIntegrationService -Name "Guest Service Interface","Heartbeat","Key-Value Pair Exchange","Shutdown","Time Synchronization","VSS";

		Write-Verbose ("Configured Checkpoints, AutoStart/Stop and Integration Services on VM: {0}" -f $Name);

		#Add a DVD drive to the Default Controller
		Add-VMDvdDrive -VM $WorkingVM -ControllerNumber 0;
		Write-Verbose ("Added DVD drive: {0}, SCSI Controller 0" -f $Name);

		#Configure the Network Adapters
		if($NetworkAdapters -eq 0) {
			$PrimaryNIC = Get-VMNetworkAdapter -VM $WorkingVM | select -First 1;
			Remove-VMNetworkAdapter -VMNetworkAdapter $PrimaryNIC;
		} else {
			$PrimaryNIC = Get-VMNetworkAdapter -VM $WorkingVM | select -First 1;
			Rename-VMNetworkAdapter -VMNetworkAdapter $PrimaryNIC -NewName "Ethernet1";

			if($NetworkAdapters -gt 1) {
				for($i = 2; $i -le $NetworkAdapters; $i++) {
					Add-VMNetworkAdapter -VM $WorkingVM -Name ("Ethernet{0}" -f $i);
				}
				Write-Verbose ("Attached {0} Additional Network Adapter to VM: {0}" -f ($NetworkAdapters - 1));
			}
		}
		
		return $WorkingVM;
	}
}
