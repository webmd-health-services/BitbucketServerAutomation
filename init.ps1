<#
.SYNOPSIS
Initializes this repository for development.

.DESCRIPTION
The `init.ps1` script initializes this repository for development. It:

 * Installs Bitbucket Server on the local machine for use in Pester tests
#>

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
    [string]
    # Path to the root directory where Bitbucket Server is installed.
    $BitbucketInstallRoot = (Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian\Bitbucket'),

    [string]
    # Path to the application data directory for Bitbucket Server.
    $BitbucketApplicationDataPath = (Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian\ApplicationData\Bitbucket'),

    [Switch]
    # Removes any previously downloaded packages and re-downloads them.
    $Clean,

    [string]
    # Version of Bitbucket Server to install.
    $Version = '5.2.3'
)

Set-StrictMode -Version 'Latest'
#Requires -Version 4
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

$bbServerCredPath = Join-Path -Path $PSScriptRoot -ChildPath '.bbservercredential'
if( (Test-Path -Path $bbServerCredPath -PathType Leaf) )
{
    $credential = Import-Clixml -Path $bbServerCredPath
}
else
{
    $rng = New-Object 'Security.Cryptography.RNGCryptoServiceProvider'
    $randomBytes = New-Object 'byte[]' 12
    $passwordChars = '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $password = New-Object 'Security.SecureString'
    $rng.GetBytes($randomBytes)
    foreach( $byte in $randomBytes )
    {
        $password.AppendChar( $passwordChars[ $byte % $passwordChars.Count ] )
    }

    $credential = New-Object 'Management.Automation.PSCredential' 'admin',$password
    $credential | Export-Clixml -Path $bbServerCredPath
}

$bbPropertiesPath = Join-Path -Path $BitbucketApplicationDataPath -ChildPath 'shared\bitbucket.properties'
$bbServerUri = 'http://{0}:7990/' -f $env:COMPUTERNAME.ToLowerInvariant()
if( -not (Test-Path -Path $bbPropertiesPath -PathType Leaf) )
{
    $licensePath = Join-Path -Path $PSScriptRoot -ChildPath '.bbserverlicense'
    if( -not (Test-Path -Path $licensePath -PathType Leaf) )
    {
        Write-Error -Message ('Bitbucket Server license file ''{0}'' does not exist. Atlassian has donated a license to the project for use in automated tests. If you are a trusted contributor to the project, please request a copy of this license from the project owners and maintainers. Otherwise, please request a trial/evaluation license from Atlassian.' -f $licensePath)
        return
    }

    $license = Get-Content -Path $licensePath | ForEach-Object { $_.TrimEnd('\') + '\' }
    $license = $license -join [Environment]::NewLine
    $license = $license.TrimEnd('\')

    @"
setup.displayName=Bitbucket Server Automation
setup.baseUrl= $($bbServerUri)
setup.license= $($license)
setup.sysadmin.username=$($credential.UserName)
setup.sysadmin.password=$($credential.GetNetworkCredential().Password)
setup.sysadmin.displayName=Administrator
setup.sysadmin.emailAddress=nobody@example.com
"@ | Set-Content -Path $bbPropertiesPath
}

Get-Service -Name '*Bitbucket*' | Start-Service
Start-Sleep -Seconds 15

$currentActivity = 'Waiting for Bitbucket Server {0} to Start' -f $Version
$status = 'Please wait. This could take several minutes'
Write-Progress -Activity $currentActivity -Status $status
Write-Verbose -Message $currentActivity

$percentComplete = 1
do
{
    Write-Progress -Activity $currentActivity -Status $status -PercentComplete ($percentComplete++)
    $result = Invoke-WebRequest -Uri $bbServerUri -Verbose:$false
    if( $result )
    {
        $status = $result.StatusCode
        $title = $result.ParsedHtml.Title
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
