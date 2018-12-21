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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$projectKey = 'SBBSPRS'
$repo = $null
$repoName = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Set-BBServerPullRequestSetting Tests'

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepositoryWithDefaultPRSettings
{
    [CmdletBinding()]
    param(
    )

    $Global:Error.Clear()
}

function WhenUpdatingPullRequestSettings
{
    [CmdletBinding()]
    param(
        [string[]]
        $SettingName,
        
        [object[]]
        $WithValue
    )
    
    $pullRequestSettingConfig = @{}
    for($x = 0; $x -lt $SettingName.Length; $x++)
    {
        $pullRequestSettingConfig += @{ $SettingName[$x] = $WithValue[$x] }
    }
    
    Set-BBServerPullRequestSetting -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName @pullRequestSettingConfig
}

function ThenTheSettingShouldBeUpdated
{
    [CmdletBinding()]
    param(
        [string[]]
        $SettingName,
        
        [object[]]
        $WithValue
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
    
    for($x = 0; $x -lt $SettingName.Length; $x++)
    {
        It ('should set the PR setting ''{0}'' to a value of ''{1}''' -f $SettingName[$x], $WithValue[$x]) {
            Get-BBServerPullRequestSetting -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -SettingName $SettingName[$x] | Should Be $WithValue[$x]
        }
    }
}

Describe 'Set-BBServerPullRequestSetting.when updating the ''requiredApprovers'' pull request setting' {
    Init
    GivenARepositoryWithDefaultPRSettings
    WhenUpdatingPullRequestSettings 'requiredApprovers' -WithValue 3
    ThenTheSettingShouldBeUpdated 'requiredApprovers' -WithValue 3
}

Describe 'Set-BBServerPullRequestSetting.when updating the ''requiredAllApprovers'' pull request setting' {
    Init
    GivenARepositoryWithDefaultPRSettings
    WhenUpdatingPullRequestSettings 'requiredAllApprovers' -WithValue $true
    ThenTheSettingShouldBeUpdated 'requiredAllApprovers' -WithValue $true
}

Describe 'Set-BBServerPullRequestSetting.when requesting to update multiple pull request settings' {
    Init
    GivenARepositoryWithDefaultPRSettings
    WhenUpdatingPullRequestSettings 'requiredApprovers', 'requiredAllApprovers' -WithValue '6', $true
    ThenTheSettingShouldBeUpdated 'requiredApprovers', 'requiredAllApprovers' -WithValue '6', $true
}
