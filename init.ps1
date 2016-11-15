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

$packagesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'packages'

$nugetPath = Join-Path -Path $PSScriptRoot -ChildPath 'nuget.exe'

if( $Clean )
{
    $nugetPath | Remove-Item
    $packagesRoot | Remove-Item -Recurse
}

if( -not (Test-Path -Path $nugetPath -PathType Leaf) )
{
    Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $nugetPath
}

& $nugetPath install 'Pester' -OutputDirectory $packagesRoot
& $nugetPath install 'Carbon' -OutputDirectory $packagesRoot

$carbonDir = Get-Item -Path (Join-Path -Path $packagesRoot -ChildPath 'Carbon.*.*.*\Carbon')
& (Join-Path -Path $carbonDir -ChildPath 'Import-Carbon.ps1' -Resolve)

Install-Junction -Link (Join-Path -Path $packagesRoot -ChildPath 'Carbon') -Target $carbonDir.FullName

$pesterdir = Get-Item -Path (Join-Path -Path $packagesRoot -ChildPath 'Pester.*.*.*\tools')
Install-Junction -Link (Join-Path -Path $packagesRoot -ChildPath 'Pester') -Target $pesterdir.FullName
