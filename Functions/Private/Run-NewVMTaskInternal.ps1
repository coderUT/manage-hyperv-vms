function Run-NewVMTaskInternal {
	<#
		.SYNOPSIS
		Run the VM Creation Logic Internally

		.DESCRIPTION
		Runs the VM Creation Logic internally. All parameter validation should be
		done by calling methods as it will also be done by internal worker methods
		called from this function.

		Memory parameter should have a value >= 256MB for static memory configuration
		otherwise set the Memory parameter to -1 and set values >= 256MB for MinimumMemory,
		MaximumMemory and StartupMemory parameters which defines a dynamic memory
		configuration.	
		
		This function either returns a reference to the created VM (if successful) or NULL
		if there was an error.

		.PARAMETER Name
		Name of the Hyper-V VM to create

		.PARAMETER Version
		Hyper-V VM Version. This value cannnot be downgraded after a VM is created,
		defaults to the default version for the host where this script is run

		.PARAMETER NetworkAdapters
		VM defaults to a single network adapter, specify a total number of adapters or 0 for no adapters

		.PARAMETER Memory
		Set to -1 to use dynamic memory or set a value >= 256MB for static memory configuration 

		.PARAMETER MinimumMemory
		Set the minimum memory >= 256MB for the VM if using dynamic memory. Required to
		use dynamic memory.

		.PARAMETER MaximumMemory
		Set the maximum memory for the VM if using dynamic memory. Must be greater than
		minimum memory. Required to use dynamic memory.

		.PARAMETER StartupMemory
		Set the startup memory for a VM if using dynamic memory. Must be greater
		than or equal to minimum memory and less than or equal to maximum memory. Required to
		use dynamic memory
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, HelpMessage="New VM Name")]
		[string] $Name,

		[Parameter(Mandatory=$true, HelpMessage="New VM Version")]
		[string] $Version,

		[Parameter(Mandatory=$true, HelpMessage="Specify Number of Network Adapters for the VM")]
		[int] $NetworkAdapters,

		[Parameter(Mandatory=$true, HelpMessage="Set VM Memory")]
		[int64] $Memory,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Minimum Memory")]
		[int64] $MinimumMemory,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Maximum Memory")]
		[int64] $MaximumMemory,

		[Parameter(Mandatory=$true, HelpMessage="Set Dynamic Memory Startup Memory")]
		[int64] $StartupMemory
	)

	process {
		If($PSBoundParameters['Debug']) { $DebugPreference = 'Continue'; }
		$WorkingVM = $null
		try {
			$UseVerbose = $false;
			If($PSBoundParameters['Verbose']) { $UseVerbose = $true; }

			$DynamicMemoryCfg = @{
				StartupMemory=$StartupMemory;
				MinimumMemory=$MinimumMemory;
				MaximumMemory=$MaximumMemory;
			};

			#Validate Dynamic Memory Parameters before creating any VMs if we will be using dynamic
			#memory configuration
			if($Memory -le 0) {
				if($UseVerbose) { Set-VMInternalDynamicMemory @DynamicMemoryCfg -ValidateConfigurationOnly -Verbose; }
				else { Set-VMInternalDynamicMemory @DynamicMemoryCfg -ValidateConfigurationOnly; }
			}

			If($UseVerbose) { $WorkingVM = New-VMInternal -Name $Name -Version $Version -NetworkAdapters $NetworkAdapters -Verbose;
			} else { $WorkingVM = New-VMInternal -Name $Name -Version $Version -NetworkAdapters $NetworkAdapters; }
			
			#We default to static mode if parameter Memory is set (so were giving static memory configuration
			#a higher preference)
			if($Memory -gt 0) {
				if($UseVerbose) { $WorkingVM = Set-VMInternalStaticMemory -Name $Name -Memory $Memory -Verbose;
				} else { $WorkingVM = Set-VMInternalStaticMemory -Name $Name -Memory $Memory; }
			} else {
				$DynamicMemoryCfg.Add('Name', $Name);
				Foreach($Key in $DynamicMemoryCfg.Keys) {
					Write-Debug ("DynamicMemoryCfg: {0}={1}" -f $Key, $DynamicMemoryCfg[$Key]);
				}
				if($UseVerbose) { $WorkingVM = Set-VMInternalDynamicMemory @DynamicMemoryCfg -Verbose;			
				} else { $WorkingVM = Set-VMInternalDynamicMemory @DynamicMemoryCfg; }
			}
		} catch {
			if(Get-VM | where {$_.Name -eq $Name}) {
				Remove-VM $Name -Force;
			}
			Write-Error ("Failed to create the new VM: {0}" -f $_.Exception.Message);
			Write-Debug $_.ScriptStackTrace;
			return $null;
		}
		return $WorkingVM;
	}
}
