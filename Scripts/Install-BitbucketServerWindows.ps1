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
    # Version of Bitbucket Server to install.
    $Version,

    [string]
    # Path to the root directory where Bitbucket Server is installed.
    $BitbucketInstallRoot = (Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian\Bitbucket'),

    [string]
    # Path to the application data directory for Bitbucket Server.
    $BitbucketApplicationDataPath = (Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian\ApplicationData\Bitbucket'),

    [Switch]
    # Removes any previously downloaded packages and re-downloads them.
    $Clean
)

Set-StrictMode -Version 'Latest'
#Requires -Version 5.1
#Requires -RunAsAdministrator

# Install a local copy of Bitbucket Server.
$bitbucketInstallPath = Join-Path -Path $BitbucketInstallRoot -ChildPath $Version
$installerPath = Join-Path -Path $env:TEMP -ChildPath ('atlassian-bitbucket-{0}-x64.exe' -f $Version)

if( $Clean -and (Test-Path -Path $installerPath -PathType Leaf) )
{
    Remove-Item -Path $installerPath -Force
}

if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    $downloadUri = 'https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-{0}-x64.exe' -f $Version
    $currentActivity = ('Downloading Bitbucket Server {0}' -f $Version)
    Write-Progress -Activity $currentActivity
    Write-Verbose -Message $currentActivity
    Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $installerPath
    Write-Progress -Completed -Activity $currentActivity
}

if( -not (Test-Path -Path $installerPath) )
{
    Write-Error -Message ('Bitbucket Server {0} installer failed to download.' -f $Version)
    return
}

if( -not (Get-Service -Name '*Bitbucket*') )
{
    $installerResponseVarfilePath = Join-Path -Path $env:TEMP -ChildPath ('atlassian.bitbucket.server.response.{0}.varfile' -f [IO.Path]::GetRandomFileName())

    @"
# install4j response file for Bitbucket $($Version)
app.bitbucketHome=$($BitbucketApplicationDataPath -replace '(:|\\)','\$1')
app.defaultInstallDir=$($bitbucketInstallPath -replace '(:|\\)','\$1')
app.install.service`$Boolean=true
app.programGroupName=Bitbucket
installation.is.new.install=true
installation.type=INSTALL
launch.application`$Boolean=false
portChoice=default
sys.adminRights`$Boolean=true
sys.languageId=en
"@ | Set-Content -Path $installerResponseVarfilePath

    $currentActivity = 'Installing Bitbucket Server {0}' -f $Version
    try
    {
        Write-Progress -Activity $currentActivity -Status 'Please wait. This could take several minutes.'
        Write-Verbose -Message $currentActivity
        Start-Process -Wait $installerPath -ArgumentList '-q','-varfile',$installerResponseVarfilePath
    }
    finally
    {
        Write-Progress -Activity $currentActivity -Completed
        Remove-Item -Path $installerResponseVarfilePath
    }
}

if( -not (Test-Path -Path $BitbucketApplicationDataPath -PathType Container) )
{
    Write-Error -Message ('It looks like Bitbucket Server wasn''t installed because ''{0}'' doesn''t exist.' -f $BitbucketApplicationDataPath)
    return
}

$bbPropertiesPath = Join-Path -Path $BitbucketApplicationDataPath -ChildPath 'shared\bitbucket.properties'
if( -not (Test-Path -Path $bbPropertiesPath -PathType Leaf) )
{
    @"
setup.displayName=Bitbucket Server Automation
setup.baseUrl=http://127.0.0.1:7990/
setup.license=$($License)
setup.sysadmin.username=$($Credential.UserName)
setup.sysadmin.password=$($Credential.GetNetworkCredential().Password)
setup.sysadmin.displayName=Administrator
setup.sysadmin.emailAddress=nobody@example.com
"@ | Set-Content -Path $bbPropertiesPath
}

Get-Service -Name '*Bitbucket*' | Start-Service
