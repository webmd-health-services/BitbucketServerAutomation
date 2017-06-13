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

$projectKey = 'GBBSBRANCH'
$repoName = 'RepositoryWithBranches'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerBranch Tests'

New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null
$initBranches = ('master', 'develop', 'release', 'hotfix/HotfixBranch', 'feature/NewFeatureOne', 'feature/NewFeatureTwo')

function GivenARepositoryWithBranches
{
    [CmdletBinding()]
    param(
    )
    
    $getBranches = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName
    if( !$getBranches )
    {
        $targetRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName
        $repoClonePath = $targetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $tempRepoRoot = Join-Path -Path $env:TEMP -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $tempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $tempRepoRoot
        try
        {
            git clone $repoClonePath $repoName
            cd $repoName
            git commit --allow-empty -m 'Initializing repository for `Get-BBServerBranch` tests'
            git push -u origin
        }
        finally
        {
            Pop-Location
            Remove-Item -Path $tempRepoRoot -Recurse -Force
        }
    }

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
    GivenARepositoryWithBranches
    WhenGettingBranches -ShouldReturnAllBranches
}

Describe 'Get-BBServerBranch.when returning only the ''master'' branch' {
    GivenARepositoryWithBranches
    WhenGettingBranches -WithBranchSearchFilter 'master' -ShouldReturnSpecificBranches ('master')
}

Describe 'Get-BBServerBranch.when returning branches that match the wildcard search ''feature*''' {
    GivenARepositoryWithBranches
    WhenGettingBranches -WithBranchSearchFilter 'feature*' -ShouldReturnSpecificBranches ('feature/NewFeatureOne', 'feature/NewFeatureTwo')
}

Describe 'Get-BBServerBranch.when searching for a branch that does not exist' {
    GivenARepositoryWithBranches
    WhenGettingBranches -WithBranchSearchFilter 'NonExistentBranch' -ShouldNotReturnAnyBranches
}
