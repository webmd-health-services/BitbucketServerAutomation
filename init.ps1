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
    # Name for the Bitbucket Server container. Defaults to "bitbucket".
    [String] $ContainerName = 'bitbucket',

    # Name for the Bitbucket Server image that is built to run tests against. Defaults to "bitbucket-testinstance".
    [String] $ImageName = 'bitbucket-testinstance',

    # Credential object for the default Administrator account on the local Bitbucket Server instance. Defualts to username "admin" and password "admin".
    [pscredential] $Credential
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$licensePath = Join-Path -Path $PSScriptRoot -ChildPath '.bbserverlicense'
if( -not (Test-Path -Path $licensePath -PathType Leaf) )
{
    Write-Error -Message ('Bitbucket Server license file "{0}" does not exist. Atlassian has donated a license to the project for use in automated tests. If you are a trusted contributor to the project, please request a copy of this license from the project owners and maintainers. Otherwise, please request a trial/evaluation license from Atlassian.' -f $licensePath)
    return
}
$license = Get-Content -Path $licensePath | ForEach-Object { $_.TrimEnd('\') + '\' }
$license = $license -join ''
$license = $license.TrimEnd('\')

if (-not $Credential)
{
    $Credential = [pscredential]::New('admin', (ConvertTo-SecureString 'admin' -AsPlainText -Force))
}
$bbServerCredPath = Join-Path -Path $PSScriptRoot -ChildPath '.bbservercredential'
$Credential | Export-Clixml -Path $bbServerCredPath

if (-not (Get-Command -Name 'docker'))
{
    return
}

$dockerOS = docker version -f "{{ .Server.Os }}"
if ($dockerOS -ne 'linux')
{
    $msg = 'Unable to run container. The Bitbucket Server Docker image is a Linux container but Docker on your ' +
           "system is configured to run ""${dockerOS}""."
    Write-Error -Message $msg
    return
}

$containerExists = docker ps -a -q --filter name=$ContainerName
if($containerExists)
{
    $containerRunning = docker ps -a -q --filter name=$ContainerName --filter status=running
    if ($containerRunning)
    {
        Write-Information "Container ${ContainerName} exists and running."
        return
    }

    Write-Information -Message "Starting ""${ContainerName}""."
    docker start $ContainerName
    return
}

$dockerfilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Dockerfile' -Resolve

$buildArgs = & {
    '--build-arg'
    'LICENSE={0}' -f $license

    '--build-arg'
    'USERNAME={0}' -f $Credential.UserName

    '--build-arg'
    'PASSWORD={0}' -f $Credential.GetNetworkCredential().Password
}

Write-Information "Building ${ImageName} image from ${dockerFilePath}."
docker build --pull -t $ImageName $buildArgs --file $dockerfilePath $PSScriptRoot

$danglingImages = docker images -q --filter dangling=true
if ($danglingImages)
{
    Write-Information "Removing dangling container images."
    docker rmi $danglingImages
}

Write-Information "Running ${ContainerName} container."
docker run --name=$ContainerName -d -p 7990:7990 -p 7999:7999 $ImageName

Write-Information "Waiting for Bitbucket Server to start."

Start-Sleep -Seconds 20

$bbServerUrl = 'http://127.0.0.1:7990/'
$percentComplete = 1
do
{
    try
    {
        $result = Invoke-WebRequest -Uri $bbServerUrl -UseBasicParsing -Verbose:$false
        if( $result )
        {
            $status = $result.StatusCode

            $title = ''
            if ($result.RawContent -match '<title>(.*)<\/title>')
            {
                $title = $Matches[1]
            }

            Write-Information -Message "GET ${bbServerUrl} -> ${status}  ${title}"
            if( $status -eq 200 -and $title -notmatch '\bStarting\b' )
            {
                break
            }
        }
    }
    catch
    {
        Write-Information -Message "GET ${bbServerUrl} -> ${_}"
    }

    Start-Sleep -Seconds 5

    $percentComplete += 10

    if( $percentComplete -gt 100 )
    {
        break
    }
}
while( $true )
