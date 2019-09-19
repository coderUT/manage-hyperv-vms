function Set-VMInternalDynamicMemory {
	<#
		.SYNOPSIS
		Configure a VM with Dynamic Memory

		.DESCRIPTION
		Configure a VM with Dynamic Memory. Requires Hyper-V Powershell
		management cmdlets and permissions to manage VMs.

		.PARAMETER Name
		The Name of the Hyper-V VM to configure

		.PARAMETER MinimumMemory
		Set the minimum memory (256MB or greater) for the VM if using dynamic memory

		.PARAMETER MaximumMemory
		Set the maximum memory for the VM if using dynamic memory. Must be greater than
		minimum memory

		.PARAMETER StartupMemory
		Set the startup memory for a VM is using dynamic memory. Must be greater
		than or equal to minimum memory and less than or equal to maximum memory

		.PARAMETER ValidateConfigurationOnly
		Test that the MinimumMemory, MaximumMemory and StartupMemory parameters are logically
		valid
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false, HelpMessage="VM to configure")]
		[ValidateNotNullorEmpty()]
		[string] $Name,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Minimum Memory")]
		[ValidateScript({
			$_ -ge 256MB
		})]
		[int64] $MinimumMemory = -1,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Maximum Memory")]
		[ValidateScript({
			$_ -ge 256MB
		})]
		[int64] $MaximumMemory = -1,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Startup Memory")]
		[ValidateScript({
			$_ -ge 256MB
		})]
		[int64] $StartupMemory = -1,

		[Parameter(Mandatory=$false, HelpMessage="Validate Dynamic Memory Settings")]
		[switch] $ValidateConfigurationOnly = $false
	)

	If($MaximumMemory -lt $MinimumMemory) {
		Throw("MaximumMemory: {0}MB cannot be less than MinimumMemory: {1}MB" -f ($MaximumMemory/1MB), ($MinimumMemory/1MB));
	}
	
	If($StartupMemory -lt $MinimumMemory) {
		Throw("StartupMemory: {0}MB cannot be less than MinimumMemory: {1}MB" -f ($StartupMemory/1MB), ($MinimumMemory/1MB));
	}

	If($StartupMemory -gt $MaximumMemory) {
		Throw("StartupMemory: {0}MB cannot be greater than MaximumMemory: {1}MB" -f ($StartupMemory/1MB), ($MaximumMemory/1MB));
	}

	If(-Not $ValidateConfigurationOnly) {
		Set-VMMemory -VMName $Name -DynamicMemoryEnabled $true -StartupBytes $StartupMemory -MinimumBytes $MinimumMemory -MaximumBytes $MaximumMemory;
		Write-Verbose ("Configured VM: {0}, Dynamic Memory, Startup Memory: {1}MB, Minimum Memory: {2}MB, Maximum Memory: {3}MB" -f $Name, ($StartupMemory/1MB), ($MinimumMemory/1MB), ($MaximumMemory/1MB));
		return Get-VM $Name;
	}
}
