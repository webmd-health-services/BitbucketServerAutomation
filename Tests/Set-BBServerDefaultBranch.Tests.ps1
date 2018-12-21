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
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'SBBSDEFBRANCH'
$repo = $null
$repoRoot = $null
$repoName = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Set-BBServerDefaultBranch Tests'
$initBranches = ('master', 'develop', 'release')

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepositoryWithBranches
{
    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    $getBranches = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName
    $initBranches | ForEach-Object {
        if( $getBranches.displayId -notcontains $_ )
        {
            New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $_ -StartPoint 'master'
        }
    }
}

function WhenSettingDefaultBranch
{
    [CmdletBinding()]
    param(
        [string]
        $BranchName,

        [switch]
        $ThrowsExceptionThatBranchDoesNotExist
    )

    $Global:Error.Clear()
    
    Set-BBServerDefaultBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $BranchName -ErrorAction SilentlyContinue | Out-Null
    
    if( $ThrowsExceptionThatBranchDoesNotExist )
    {
        It 'should throw an error that the invalid branch cannot be set as the default' {
            $Global:Error | Should -Match ('A branch with the name ''{0}'' does not exist in the ''{1}'' repository and cannot be set as the default' -f $BranchName, $repoName)
        }
    }
    else
    {
        It 'should not throw any errors' {
            $Global:Error | Should BeNullOrEmpty
        }
    }
}

function ThenDefaultBranchIs
{
    [CmdletBinding()]
    param(
        [string]
        $BranchName
    )
    
    $checkBranch = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $BranchName
    
    It ('should set the ''{0}'' branch as the default for the repository' -f $BranchName) {
        $checkBranch.isDefault | Should Be $true
    }
}

Describe 'Set-BBServerDefaultBranch.when setting ''develop'' as the default branch' {
    Init
    GivenARepositoryWithBranches
    WhenSettingDefaultBranch -BranchName 'develop'
    ThenDefaultBranchIs -BranchName 'develop'
}

Describe 'Set-BBServerDefaultBranch.when setting ''master'' back to the default branch' {
    Init
    GivenARepositoryWithBranches
    WhenSettingDefaultBranch -BranchName 'master'
    ThenDefaultBranchIs -BranchName 'master'
}

Describe 'Set-BBServerDefaultBranch.when setting default branch to a non-existent branch' {
    Init
    GivenARepositoryWithBranches
    WhenSettingDefaultBranch -BranchName 'NonExistentBranch' -ThrowsExceptionThatBranchDoesNotExist
}
