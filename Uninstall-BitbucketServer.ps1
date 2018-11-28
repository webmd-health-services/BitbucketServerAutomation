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
    [Parameter(Mandatory=$true)]
    [string]
    $BitbucketInstallationPath,

    [Parameter(Mandatory=$true)]
    [string]
    $BitbucketHomePath
)

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath '.\PSModules\Carbon\*\Import-Carbon.ps1' -Resolve)

Get-Service -Name '*Bitbucket*' |
    Stop-Service -PassThru -Force |
    ForEach-Object { Uninstall-Service -Name $_.Name }

Remove-EnvironmentVariable -Name 'BITBUCKET_HOME' -ForComputer -ForUser -ForProcess
Remove-EnvironmentVariable -Name 'BITBUCKET_INSTALLATION' -ForComputer -ForUser -ForProcess
Uninstall-User -Username 'atlbitbucket'
Remove-Item -Path 'HKLM:\SOFTWARE\Atlassian\Bitbucket' -Recurse -Force -ErrorAction Ignore
Remove-Item -Path $BitbucketInstallationPath -Recurse -Force
Remove-Item -Path $BitbucketHomePath -Recurse -Force
