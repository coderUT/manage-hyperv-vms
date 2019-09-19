$ModuleScriptFiles = Get-ChildItem -Filter '*.ps1' -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\Private'),(Join-Path -Path $PSScriptRoot -ChildPath 'Functions\Public')
ForEach($ScriptFile in $ModuleScriptFiles) {
	try {
		. $ScriptFile.FullName
	} catch {
		Write-Error ("Module failed to load function: {0}" -f $ScriptFile);
	}
}
