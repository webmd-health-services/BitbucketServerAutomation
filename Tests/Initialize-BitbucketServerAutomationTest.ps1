
& (Join-Path -Path $PSScriptRoot -ChildPath '..\BitbucketServerAutomation\Import-BitbucketServerAutomation.ps1' -Resolve)
& (Join-Path -Path $PSScriptRoot -ChildPath '..\packages\Carbon\Import-Carbon.ps1' -Resolve)

if( (Get-Module -Name 'BBServerAutomationTest') )
{
    Remove-Module -Name 'BBServerAutomationTest'
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'BBServerAutomationTest\BBServerAutomationTest.psm1' -Resolve)
