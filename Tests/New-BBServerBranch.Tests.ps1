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

$projectKey = 'NBBSBRANCH'
$repoName = 'RepositoryWithBranches'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerBranch Tests'

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
}

function WhenCreatingANewBranch
{
    [CmdletBinding()]
    param(
        [string]
        $BranchName,

        [string]
        $StartPoint,

        [switch]
        $ShouldThrowInvalidBranchPointException,

        [switch]
        $ShouldThrowDuplicateBranchException
    )

    $Global:Error.Clear()
    
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $BranchName -StartPoint $StartPoint -ErrorAction SilentlyContinue | Out-Null
    
    if( $ShouldThrowInvalidBranchPointException )
    {
        It 'should throw an error that an invalid branch start point was defined' {
            $Global:Error | Should -Match ('Branch point ''{0}'' does not exist in this repository' -f $StartPoint)
        }
    }
    elseif( $ShouldThrowDuplicateBranchException )
    {
        It 'should throw an error that the given branch name already exists' {
            $Global:Error | Should -Match ('A branch with the name ''{0}'' already exists' -f $BranchName)
        }
    }
    else
    {
        It 'should not throw any errors' {
            $Global:Error | Should BeNullOrEmpty
        }
    }
}

function ThenNewBranch
{
    [CmdletBinding()]
    param(
        [string]
        $ShouldBeCreated,

        [string]
        $ShouldNotBeCreated,

        [string]
        $ShouldNotBeCreatedAndOnlyExistOnce
    )

    if( $ShouldBeCreated )
    {
        $checkBranch = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $ShouldBeCreated

        It ('should create a new branch named ''{0}''' -f $ShouldBeCreated) {
            $checkBranch.displayId -eq $ShouldBeCreated | Should Be $true
        }
    }

    if( $ShouldNotBeCreated )
    {
        $checkBranch = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $ShouldNotBeCreated

        It ('should not create a new branch named ''{0}''' -f $ShouldNotBeCreated) {
            $checkBranch | Should BeNullOrEmpty
        }
    }

    if( $ShouldNotBeCreatedAndOnlyExistOnce )
    {
        [array]$checkBranch = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $ShouldNotBeCreatedAndOnlyExistOnce

        It ('should not create a new branch named ''{0}'', which should only exist once' -f $ShouldNotBeCreatedAndOnlyExistOnce) {
            $checkBranch.Count | Should Be 1
        }
    }
}

Describe 'New-BBServerBranch.when creating a new branch based on an existing ''master'' branch' {
    GivenARepository
    WhenCreatingANewBranch -BranchName 'branch_cloned_from_master' -StartPoint 'master'
    ThenNewBranch -ShouldBeCreated 'branch_cloned_from_master'
}

Describe 'New-BBServerBranch.when creating a new branch based on an existing Commit ID' {
    GivenARepository
    $getBranch = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName 'master'
    $newBranchName = ('branch_cloned_from_commitid_{0}' -f $getBranch.latestCommit)
    WhenCreatingANewBranch -BranchName $newBranchName -StartPoint $getBranch.latestCommit
    ThenNewBranch -ShouldBeCreated $newBranchName
}

Describe 'New-BBServerBranch.when creating a branch from an invalid StartPoint' {
    GivenARepository
    WhenCreatingANewBranch -BranchName 'branch_cloned_from_invalid_start' -StartPoint 'InvalidStartPoint' -ShouldThrowInvalidBranchPointException
    ThenNewBranch -ShouldNotBeCreated 'branch_cloned_from_invalid_start'
}

Describe 'New-BBServerBranch.when creating a branch with a name that already exists' {
    GivenARepository
    WhenCreatingANewBranch -BranchName 'branch_cloned_from_master' -StartPoint 'master' -ShouldThrowDuplicateBranchException
    ThenNewBranch -ShouldNotBeCreatedAndOnlyExistOnce 'branch_cloned_from_master'
}
