
.\init.ps1

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'packages\Pester' -Resolve)

$result = Invoke-Pester -Script (Join-Path -Path $PSScriptRoot -ChildPath 'Tests' -Resolve) -OutputFormat NUnitXml -OutputFile (Join-Path -Path $PSScriptRoot -ChildPath 'pester.xml') -PassThru

exit $result.FailedCount
