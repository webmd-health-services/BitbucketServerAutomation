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

[CmdletBinding(DefaultParameterSetName='Build')]
param(
    [Parameter(Mandatory=$true,ParameterSetName='Clean')]
    [Switch]
    # Runs the build in clean mode, which removes any files, tools, packages created by previous builds.
    $Clean,

    [Parameter(Mandatory=$true,ParameterSetName='Initialize')]
    [Switch]
    # Initializes the repository.
    $Initialize
)


#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path -Path $PSScriptRoot -ChildPath '.whiskey\Import-Whiskey.ps1' -Resolve)

$configPath = Join-Path -Path $PSScriptRoot -ChildPath 'whiskey.yml' -Resolve

$optionalArgs = @{ }
if( $Clean )
{
    $optionalArgs['Clean'] = $true
}

if( $Initialize )
{
    $optionalArgs['Initialize'] = $true
}

$context = New-WhiskeyContext -Environment 'Dev' -ConfigurationPath $configPath

$apiKeys = @{
    'PowerShellGallery' = 'POWERSHELL_GALLERY_API_KEY'
    'github.com' = 'GITHUB_ACCESS_TOKEN'
}

$apiKeys.Keys |
    Where-Object { Test-Path -Path ('env:{0}' -f $apiKeys[$_]) } |
    ForEach-Object {
        $apiKeyID = $_
        $envVarName = $apiKeys[$apiKeyID]
        Write-Verbose ('Adding API key "{0}" with value from environment variable "{1}".' -f $apiKeyID,$envVarName)
        Add-WhiskeyApiKey -Context $context -ID $apiKeyID -Value (Get-Item -Path ('env:{0}' -f $envVarName)).Value
    }

Invoke-WhiskeyBuild -Context $context @optionalArgs
