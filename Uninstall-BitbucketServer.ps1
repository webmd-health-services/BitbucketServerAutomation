[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $BitbucketInstallationPath,

    [Parameter(Mandatory=$true)]
    [string]
    $BitbucketHomePath
)

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1' -Resolve)

Get-Service -Name '*Bitbucket*' | 
    Stop-Service -PassThru -Force |
    ForEach-Object { Uninstall-Service -Name $_.Name }
        
Remove-EnvironmentVariable -Name 'BITBUCKET_HOME' -ForComputer -ForUser -ForProcess
Remove-EnvironmentVariable -Name 'BITBUCKET_INSTALLATION' -ForComputer -ForUser -ForProcess
Uninstall-User -Username 'atlbitbucket'
Remove-Item -Path 'HKLM:\SOFTWARE\Atlassian\Bitbucket' -Recurse -Force -ErrorAction Ignore
Remove-Item -Path $BitbucketInstallationPath -Recurse -Force
Remove-Item -Path $BitbucketHomePath -Recurse -Force
