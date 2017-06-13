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

$projectKey = 'SBBSDEFBRANCH'
$repoName = 'RepositoryWithBranches'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Set-BBServerDefaultBranch Tests'

New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null
$initBranches = ('master', 'develop', 'release')

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
        $tempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $tempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $tempRepoRoot
        try
        {
            git clone $repoClonePath $repoName 2>&1
            cd $repoName
            git commit --allow-empty -m 'Initializing repository for `Get-BBServerBranch` tests' 2>&1
            git push -u origin 2>&1
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
            $Global:Error | Should -Match ('A branch with the name ''{0}'' does not exist in the ''RepositoryWithBranches'' repository and cannot be set as the default' -f $BranchName, $repoName)
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
    GivenARepositoryWithBranches
    WhenSettingDefaultBranch -BranchName 'develop'
    ThenDefaultBranchIs -BranchName 'develop'
}

Describe 'Set-BBServerDefaultBranch.when setting ''master'' back to the default branch' {
    GivenARepositoryWithBranches
    WhenSettingDefaultBranch -BranchName 'master'
    ThenDefaultBranchIs -BranchName 'master'
}

Describe 'Set-BBServerDefaultBranch.when setting default branch to a non-existent branch' {
    GivenARepositoryWithBranches
    WhenSettingDefaultBranch -BranchName 'NonExistentBranch' -ThrowsExceptionThatBranchDoesNotExist
}
