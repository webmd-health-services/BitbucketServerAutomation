[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$moduleRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'BitbucketServerAutomation' -Resolve)
$manifest = Test-ModuleManifest -Path (Join-Path -Path $moduleRoot -ChildPath 'BitbucketServerAutomation.psd1' -Resolve)
if( -not $manifest )
{
    return
}

$privateData = $manifest.PrivateData['PSData']

$nugetKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '.psgallerykey'
if( -not (Test-Path -Path $nugetKeyPath -PathType Leaf) )
{
    $key = Read-Host -Prompt 'Please enter your PowerShell Gallery API key:' -AsSecureString
    $key | Export-Clixml -Path $nugetKeyPath
}

$key = Import-Clixml -Path $nugetKeyPath
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($key)
$key = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Publish-Module -Path $moduleRoot -NuGetApiKey $key -Repository 'PSGallery' -ReleaseNotes $privateData['ReleaseNotes'] -Tags $privateData['Tags'] -LicenseUri $privateData['LicenseUri'] -ProjectUri $privateData['ProjectUri']
