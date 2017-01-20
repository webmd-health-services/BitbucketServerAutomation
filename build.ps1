
.\init.ps1 -Verbose:$VerbosePreference

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Pester' -Resolve)

$result = Invoke-Pester -Script (Join-Path -Path $PSScriptRoot -ChildPath 'Tests' -Resolve) -OutputFormat NUnitXml -OutputFile (Join-Path -Path $PSScriptRoot -ChildPath 'pester.xml') -PassThru

exit $result.FailedCount
