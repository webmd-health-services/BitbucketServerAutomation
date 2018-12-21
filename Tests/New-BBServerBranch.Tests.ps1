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

$projectKey = 'NBBSBRANCH'
$repo = $null
$repoRoot = $null
$repoName = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerBranch Tests'

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepository
{
    param(
        $WithBranch
    )

    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    if ($WithBranch)
    {
        New-GitBranch -Name $WithBranch -RepoRoot $repoRoot
        Update-GitRepository -Revision $WithBranch -RepoRoot $repoRoot
        Send-GitCommit -SetUpstream -RepoRoot $repoRoot -Credential $bbConnection.Credential
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
    Init
    GivenARepository
    WhenCreatingANewBranch -BranchName 'branch_cloned_from_master' -StartPoint 'master'
    ThenNewBranch -ShouldBeCreated 'branch_cloned_from_master'
}

Describe 'New-BBServerBranch.when creating a new branch based on an existing Commit ID' {
    Init
    GivenARepository
    $getBranch = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName 'master'
    $newBranchName = ('branch_cloned_from_commitid_{0}' -f $getBranch.latestCommit)
    WhenCreatingANewBranch -BranchName $newBranchName -StartPoint $getBranch.latestCommit
    ThenNewBranch -ShouldBeCreated $newBranchName
}

Describe 'New-BBServerBranch.when creating a branch from an invalid StartPoint' {
    Init
    GivenARepository
    WhenCreatingANewBranch -BranchName 'branch_cloned_from_invalid_start' -StartPoint 'InvalidStartPoint' -ShouldThrowInvalidBranchPointException
    ThenNewBranch -ShouldNotBeCreated 'branch_cloned_from_invalid_start'
}

Describe 'New-BBServerBranch.when creating a branch with a name that already exists' {
    Init
    GivenARepository -WithBranch 'branch_cloned_from_master'
    WhenCreatingANewBranch -BranchName 'branch_cloned_from_master' -StartPoint 'master' -ShouldThrowDuplicateBranchException
    ThenNewBranch -ShouldNotBeCreatedAndOnlyExistOnce 'branch_cloned_from_master'
}
