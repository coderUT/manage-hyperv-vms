function Set-VMInternalStaticMemory {
	<#
		.SYNOPSIS
		Configure a VM with Static Memory

		.DESCRIPTION
		Configure a VM with Static Memory. Requires Hyper-V Powershell
		management cmdlets and permissions to manage VMs.

		.PARAMETER Name
		The Name of the Hyper-V VM to configure

		.PARAMETER Memory
		Amount of memory to assign to the VM (256MB or greater)
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, HelpMessage="VM to configure")]
		[ValidateNotNullorEmpty()]
		[string] $Name,

		[Parameter(Mandatory=$true, HelpMessage="Set VM Memory")]
		[ValidateScript({
			$_ -ge 256MB
		})]
		[int64] $Memory
	)

	Set-VM -Name $Name -StaticMemory -MemoryStartupBytes $Memory;
	Write-Verbose ("Configured VM: {0}, Static Memory, Total Memory: {1}MB" -f $Name, ($Memory/1MB));
	return Get-VM $Name;
}
