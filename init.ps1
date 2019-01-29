<#
.SYNOPSIS
Initializes this repository for development.

.DESCRIPTION
The `init.ps1` script initializes this repository for development. It:

 * Installs Bitbucket Server on the local machine for use in Pester tests
#>

# Copyright 2016 - 2018 WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
[CmdletBinding()]
param(
    [Parameter(Mandatory, ParameterSetName='Docker')]
    [switch]
    # Run Bitbucket Server on the local machine as a Docker container.
    $Docker,

    [Parameter(Mandatory, ParameterSetName='Windows')]
    [switch]
    # Run Bitbucket Server on the local machine as a Windows service.
    $Windows,

    [string]
    # Version of Bitbucket Server to run.
    $Version = '5.16.0',

    [pscredential]
    # Credential object for the default Administrator account on the local Bitbucket Server instance. Defualts to username "admin" and password "admin".
    $Credential
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

$licensePath = Join-Path -Path $PSScriptRoot -ChildPath '.bbserverlicense'
if( -not (Test-Path -Path $licensePath -PathType Leaf) )
{
    Write-Error -Message ('Bitbucket Server license file "{0}" does not exist. Atlassian has donated a license to the project for use in automated tests. If you are a trusted contributor to the project, please request a copy of this license from the project owners and maintainers. Otherwise, please request a trial/evaluation license from Atlassian.' -f $licensePath)
    return
}
$license = Get-Content -Path $licensePath | ForEach-Object { $_.TrimEnd('\') + '\' }
$license = $license -join [Environment]::NewLine
$license = $license.TrimEnd('\')

if (-not $Credential)
{
    $Credential = New-Object -TypeName 'Management.Automation.PSCredential' -ArgumentList 'admin', (ConvertTo-SecureString 'admin' -AsPlainText -Force)
}
$bbServerCredPath = Join-Path -Path $PSScriptRoot -ChildPath '.bbservercredential'
$Credential | Export-Clixml -Path $bbServerCredPath

if ($Docker)
{
    $bitbucketInstallScript = (Join-Path -Path $PSScriptRoot -ChildPath 'Scripts\Install-BitbucketServerDocker.ps1' -Resolve)
}
elseif ($Windows)
{
    $bitbucketInstallScript = (Join-Path -Path $PSScriptRoot -ChildPath 'Scripts\Install-BitbucketServerWindows.ps1' -Resolve)
}

& $bitbucketInstallScript -Credential $credential -License $license -Version $Version -Verbose:$VerbosePreference

$currentActivity = 'Waiting for Bitbucket Server {0} to Start' -f $Version
$title = 'Please wait. This could take several minutes'
Write-Progress -Activity $currentActivity -Status $title
Write-Verbose -Message $currentActivity

Start-Sleep -Seconds 20

$bbServerUri = 'http://127.0.0.1:7990/'
$percentComplete = 1
do
{
    Write-Progress -Activity $currentActivity -Status $title -PercentComplete ($percentComplete++)
    $result = Invoke-WebRequest -Uri $bbServerUri -Verbose:$false
    if( $result )
    {
        $status = $result.StatusCode

        $title = ''
        if ($result.RawContent -match '<title>(.*)<\/title>')
        {
            $title = $Matches[1]
        }

        Write-Verbose -Message ('GET {0} -> {1}  {2}' -F $bbServerUri,$status,$title)
        if( $status -eq 200 -and $title -notmatch '\bStarting\b' )
        {
            break
        }
    }

    Start-Sleep -Seconds 5

    if( $percentComplete -gt 100 )
    {
        break
    }
}
while( $true )

Write-Progress -Activity $currentActivity -Completed
