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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\BitbucketServerAutomation\Import-BitbucketServerAutomation.ps1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Carbon') -Force

if( (Get-Module -Name 'BBServerAutomationTest') )
{
    Remove-Module -Name 'BBServerAutomationTest'
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'BBServerAutomationTest\BBServerAutomationTest.psm1' -Resolve)

$bbConnection = New-BBServerTestConnection
$netrcConfig = @"
machine $($env:COMPUTERNAME)
login $($bbConnection.Credential.UserName)
password $($bbConnection.Credential.GetNetworkCredential().Password)
"@
$netrcFile = New-Item -Name '_netrc' -Force -Path $env:USERPROFILE -ItemType 'File' -Value $netrcConfig
