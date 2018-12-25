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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$projectKey = 'GBBSPRS'
$repoName = 'RepositoryWithPRSettings'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerPullRequestSetting Tests'

$getRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore
if ( $getRepo )
{
    Remove-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -Force
}
New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName | Out-Null

function GivenARepository
{
    [CmdletBinding()]
    param(
    )

    $Global:Error.Clear()
}

function GivenPullRequestSetting
{
    [CmdletBinding()]
    param(
        [string]
        $SettingName,
        
        [object]
        $WithValue
    )
    
    $pullRequestSettingConfig = @{ $SettingName = $WithValue }
    Set-BBServerPullRequestSetting -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName @pullRequestSettingConfig
}

function WhenGettingAllPRSettings
{
    [CmdletBinding()]
    param(
    )

    $Script:prSettings = Get-BBServerPullRequestSetting -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName
    
    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function WhenGettingTheSpecificPRSetting
{
    [CmdletBinding()]
    param(
        [string]
        $SettingName
    )

    $Script:prSettings = Get-BBServerPullRequestSetting -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -SettingName $SettingName
    
    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function WhenGettingAnInvalidPRSetting
{
    [CmdletBinding()]
    param(
    )

    $invalidSettingName = 'InvalidPRSetting!'
    $Script:prSettings = Get-BBServerPullRequestSetting -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -SettingName $invalidSettingName -ErrorAction SilentlyContinue
    
    It 'should throw an error that the requested setting is not valid' {
        $Global:Error[0] | Should Match 'is not a valid Pull Request configuration setting'
    }

    It 'should throw an error that a property with the name of the requested setting does not exist' {
        $Global:Error[1] | Should Match ('The property ''{0}'' cannot be found on this object.' -f $invalidSettingName)
    }
}

function ThenAllPRSettingsShouldBeReturned
{
    [CmdletBinding()]
    param(
    )

    It 'should return a valid object containing all PR settings' {
        $Script:prSettings | should BeOfType System.Object
    }
    
    It 'should return current PR setting ''mergeConfig''' {
        $Script:prSettings | Should Match 'mergeConfig'
    }

    It 'should return current PR setting ''requiredApprovers''' {
        $Script:prSettings | Should Match 'requiredApprovers'
    }

    It 'should return current PR setting ''requiredAllApprovers''' {
        $Script:prSettings | Should Match 'requiredAllApprovers'
    }

    It 'should return current PR setting ''requiredAllTasksComplete''' {
        $Script:prSettings | Should Match 'requiredAllTasksComplete'
    }

    It 'should return current PR setting ''requiredSuccessfulBuilds''' {
        $Script:prSettings | Should Match 'requiredSuccessfulBuilds'
    }
}

function ThenASinglePRSettingShouldBeReturned
{
    [CmdletBinding()]
    param(
        [string]
        $SettingName,
        
        [object]
        $WithValue
    )

    It ('should return the specific PR setting ''{0}'' with a value of ''{1}''' -f $SettingName, $WithValue) {
        $Script:prSettings | Should Be $WithValue
    }
}

Describe 'Get-BBServerPullRequestSetting.when returning all pull request settings for the repository' {
    GivenARepository
    WhenGettingAllPRSettings
    ThenAllPRSettingsShouldBeReturned
}

Describe 'Get-BBServerPullRequestSetting.when returning a specific pull request setting' {
    GivenARepository
    GivenPullRequestSetting 'requiredApprovers' -WithValue 5
    WhenGettingTheSpecificPRSetting 'requiredApprovers'
    ThenASinglePRSettingShouldBeReturned 'requiredApprovers' -WithValue 5
}

Describe 'Get-BBServerPullRequestSetting.when requesting an invalid pull request setting' {
    GivenARepository
    WhenGettingAnInvalidPRSetting
}
