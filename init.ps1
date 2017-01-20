<#
.SYNOPSIS
Initializes this repository for development.

.DESCRIPTION
The `init.ps1` script initializes this repository for development. It:

 * Installs NuGet packages for Pester
#>
[CmdletBinding()]
param(
    [Switch]
    # Removes any previously downloaded packages and re-downloads them.
    $Clean
)

Set-StrictMode -Version 'Latest'
#Requires -Version 4

foreach( $moduleName in @( 'Pester', 'Carbon' ) )
{
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $moduleName
    if( (Test-Path -Path $modulePath -PathType Container) )
    {
        if( $Clean )
        {
            Remove-Item -Path $modulePath -Recurse -Force
        }

        continue
    }

    Save-Module -Name $moduleName -Path $PSScriptRoot

    $versionDir = Join-Path -Path $modulePath -ChildPath '*.*.*'
    if( (Test-Path -Path $versionDir -PathType Container) )
    {
        $versionDir = Get-Item -Path $versionDir
        Get-ChildItem -Path $versionDir -Force | Move-Item -Destination $modulePath -Verbose
        Remove-Item -Path $versionDir
    }
}

$chocoPath = Get-Command -Name 'choco.exe' -ErrorAction Ignore | Select-Object -ExpandProperty 'Source' 
if( -not $chocoPath )
{
    Invoke-WebRequest -Uri 'https://chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression
    $chocoPath = Join-Path -Path $env:PROGRAMDATA -ChildPath 'chocolatey\bin\choco.exe' -Resolve
    if( -not $chocoPath )
    {
        Write-Error -Message ('It looks like Chocolatey wasn''t installed.')
        return
    }
}

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1' -Resolve) 

# Install a local copy of Bitbucket Server.

$version = '4.6.1'
$installerPath = Join-Path -Path $env:TEMP -ChildPath ('atlassian-bitbucket-{0}-x64.exe' -f $version)
if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    $downloadUri = 'https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-{0}-x64.exe' -f $version
    $currentActivity = ('Downloading Bitbucket Server {0}' -f $version)
    Write-Progress -Activity $currentActivity
    Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $installerPath
    Write-Progress -Completed -Activity $currentActivity
}

if( -not (Test-Path -Path $installerPath) )
{
    Write-Error -Message ('Bitbucket Server {0} installer failed to download.' -f $version)
    return
}

$installRoot = Join-Path -Path $env:SystemDrive -ChildPath 'Atlassian'
$bitbucketHomePath = Join-Path -Path $installRoot -ChildPath 'ApplicationData\Bitbucket'
if( -not (Get-Service -Name '*Bitbucket*') )
{
    $installerResponseVarfilePath = Join-Path -Path $env:TEMP -ChildPath ('atlassian.bitbucket.server.response.{0}.varfile' -f [IO.Path]::GetRandomFileName())

    @"
# install4j response file for Bitbucket $($version)
app.bitbucketHome=$($bitbucketHomePath -replace '(:|\\)','\$1')
app.defaultInstallDir=$($installRoot -replace '(:|\\)','\$1')\\Bitbucket\\$($version)
app.install.service`$Boolean=true
app.programGroupName=Bitbucket
installation.is.new.install=true
installation.type=INSTALL
launch.application`$Boolean=false
portChoice=default
sys.adminRights`$Boolean=true
sys.languageId=en
"@ | Set-Content -Path $installerResponseVarfilePath

    $currentActivity = 'Installing Bitbucket Server {0}' -f $version
    try
    {
        Write-Progress -Activity $currentActivity -Status 'Please wait. This could take several minutes.'
        Start-Process -Wait $installerPath -ArgumentList '-q','-varfile',$installerResponseVarfilePath
    }
    finally
    {
        Write-Progress -Activity $currentActivity -Completed
        Remove-Item -Path $installerResponseVarfilePath
    }
}

if( -not (Test-Path -Path $bitbucketHomePath -PathType Container) )
{
    Write-Error -Message ('It looks like Bitbucket Server wasn''t installed because ''{0}'' doesn''t exist.' -f $bitbucketHomePath)
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

$bbPropertiesPath = Join-Path -Path $bitbucketHomePath -ChildPath 'shared\bitbucket.properties'
$bbServerUri = 'http://{0}:7990/' -f $env:COMPUTERNAME.ToLowerInvariant()
if( -not (Test-Path -Path $bbPropertiesPath -PathType Leaf) )
{
    $licensePath = Join-Path -Path $PSScriptRoot -ChildPath '.bbserverlicense' -Resolve
    if( -not $licensePath )
    {
        Write-Error -Message ('Bitbucket Server license file ''{0}'' does not exist. Atlassian has donated a license to the project for use in automated tests. If you are a trusted contributor to the project, please request a copy of this license from the project owners and maintainers. Otherwise, please request a trial/evaluation license from Atlassian.')
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

$currentActivity = 'Warming up Bitbucket Server {0}' -f $version
Write-Progress -Activity $currentActivity -Status 'Please wait. This could take several minutes.'
$result = Invoke-WebRequest -Uri $bbServerUri
if( $result.StatusCode -ne 200 )
{
    $result
    Write-Error -Message ('Bitbucket Server isn''t running.')
}
Write-Progress -Activity $currentActivity -Completed
