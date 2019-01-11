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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'GBBSBRANCH'
$repo = $null
$repoName = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerBranch Tests'

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    $repo | Initialize-TestRepository -Connection $bbConnection | Write-Debug

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

$initBranches = ('master', 'develop', 'release', 'hotfix/HotfixBranch', 'feature/NewFeatureOne', 'feature/NewFeatureTwo')

function GivenARepositoryWithBranches
{
    [CmdletBinding()]
    param(
    )

    $getBranches = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName
    $initBranches | ForEach-Object {
        if( $getBranches.displayId -notcontains $_ )
        {
            New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $_ -StartPoint 'master'
        }
    }
}

function WhenGettingBranches
{
    [CmdletBinding()]
    param(
        [string]
        $WithBranchSearchFilter,

        [string[]]
        $ShouldReturnSpecificBranches,

        [switch]
        $ShouldReturnAllBranches,

        [switch]
        $ShouldNotReturnAnyBranches
    )

    $Global:Error.Clear()
    
    $bbServerBranchParams = @{}
    if( $WithBranchSearchFilter )
    {
        $bbServerBranchParams['BranchName'] = $WithBranchSearchFilter
    }
    
    [array]$getBranches = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName @bbServerBranchParams
    
    if( $ShouldReturnAllBranches )
    {
        It 'should retrieve exactly 6 branches' {
            $getBranches.Count | Should Be 6
        }

        $getBranches | ForEach-Object {
            It ('result set includes branch ''{0}''' -f $_.displayId) {
                $initBranches -contains $_.displayId | Should Be True
            }
        }
    }

    if( $ShouldReturnSpecificBranches )
    {
        It ('should retrieve exactly {0} branches' -f $ShouldReturnSpecificBranches.Count) {
            $getBranches.Count | Should Be $ShouldReturnSpecificBranches.Count
        }

        $getBranches | ForEach-Object {
            It ('result set includes branch ''{0}''' -f $_.displayId) {
                $initBranches -contains $_.displayId | Should Be True
            }
        }
    }

    if( $ShouldNotReturnAnyBranches )
    {
        It 'should not return any branches' {
            $getBranches | Should BeNullOrEmpty
        }
    }
    
    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

Describe 'Get-BBServerBranch.when returning all branches from the repository' {
    Init
    GivenARepositoryWithBranches
    WhenGettingBranches -ShouldReturnAllBranches
}

Describe 'Get-BBServerBranch.when returning only the ''master'' branch' {
    Init
    GivenARepositoryWithBranches
    WhenGettingBranches -WithBranchSearchFilter 'master' -ShouldReturnSpecificBranches ('master')
}

Describe 'Get-BBServerBranch.when returning branches that match the wildcard search ''feature*''' {
    Init
    GivenARepositoryWithBranches
    WhenGettingBranches -WithBranchSearchFilter 'feature*' -ShouldReturnSpecificBranches ('feature/NewFeatureOne', 'feature/NewFeatureTwo')
}

Describe 'Get-BBServerBranch.when searching for a branch that does not exist' {
    Init
    GivenARepositoryWithBranches
    WhenGettingBranches -WithBranchSearchFilter 'NonExistentBranch' -ShouldNotReturnAnyBranches
}
