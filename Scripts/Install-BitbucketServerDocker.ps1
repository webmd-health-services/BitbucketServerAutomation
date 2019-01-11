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
    [Parameter(Mandatory)]
    [pscredential]
    # Credential object for the default Administrator account on the local Bitbucket Server instance.
    $Credential,

    [Parameter(Mandatory)]
    [string]
    # License for the local Bitbucket Server instance.
    $License,

    [Parameter(Mandatory)]
    [string]
    # Version of Bitbucket Server to run.
    $Version,

    [string]
    # Name for the Bitbucket Server container. Defaults to "bitbucket".
    $ContainerName = 'bitbucket',

    [string]
    # Name for the Bitbucket Server image that is built to run tests against. Defaults to "bitbucket-testinstance".
    $ImageName = 'bitbucket-testinstance'
)

Set-StrictMode -Version 'Latest'
#Requires -Version 5.1

if (-not (Get-Command -Name 'docker'))
{
    return
}

$dockerOS = docker version -f "{{ .Server.Os }}"
if ($dockerOS -ne 'linux')
{
    Write-Error -Message ('Unable to run container. The Bitbucket Server Docker image is a "Linux" container but Docker on your system is configured to run "{0}" containers.' -f $dockerOS)
    return
}

$containerExists = docker ps -a -q --filter name=$ContainerName
$containerExistsAndRunning = docker ps -a -q --filter name=$ContainerName --filter status=running

if ($containerExistsAndRunning)
{
    return
}
elseif($containerExists)
{
    Write-Verbose -Message ('Docker container "{0}" already exists but is not running. Starting container.' -f $ContainerName)
    docker start $ContainerName | Write-Verbose
    return
}

$dockerfilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Dockerfile' -Resolve

$buildArgs = & {
    '--build-arg'
    'VERSION={0}' -f $Version

    '--build-arg'
    'LICENSE={0}' -f $License

    '--build-arg'
    'USERNAME={0}' -f $Credential.UserName

    '--build-arg'
    'PASSWORD={0}' -f $Credential.GetNetworkCredential().Password
}

docker build --pull -t $ImageName $buildArgs --file $dockerfilePath $PSScriptRoot | Write-Verbose

docker rmi $(docker images -q --filter dangling=true) | Write-Debug

docker run --name=$ContainerName -d -p 7990:7990 -p 7999:7999 $ImageName | Write-Verbose
