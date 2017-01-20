<#
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
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

.\init.ps1 -Verbose:$VerbosePreference

$originalVerbosePref = $VerbosePreference

$result = @()
try
{
    $VerbosePreference = 'SilentlyContinue'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Pester' -Resolve) -Verbose:$false -Force

    $Global:LASTEXITCODE = 0

    $result = Invoke-Pester -Script (Join-Path -Path $PSScriptRoot -ChildPath 'Tests' -Resolve) `
                            -OutputFormat NUnitXml `
                            -OutputFile (Join-Path -Path $PSScriptRoot -ChildPath 'pester.xml') `
                            -PassThru `
                            -Verbose:$false
}
finally
{
    $VerbosePreference = $originalVerbosePref
}

$result | Format-List | Out-String | Write-Verbose

if( $result.FailedCount )
{
    throw ('{0} tests failed.' -f $result.FailedCount)
}
