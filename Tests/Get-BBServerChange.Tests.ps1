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
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'GBBSCHANGE'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerChange Tests' 
$repo = $null
$repoRoot = $null
$repoName = $null
$commitHash = $null

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
    [CmdletBinding()]
    param(
        $BranchName
    )

    Push-Location -Path $repoRoot
    try
    {
        New-Item -Path 'file' -ItemType File
        Add-GitItem -Path 'file'
        Save-GitCommit -Message 'Initializing repository for `Get-BBServerChange` tests'
        Send-GitCommit -Credential $bbConnection.Credential

        New-GitBranch -Name $BranchName
        Update-GitRepository -Revision $BranchName

        New-Item -Path 'test.txt' -ItemType 'File' -Force
        Add-GitItem -Path 'test.txt'
        $script:commitHash = Save-GitCommit -Message 'adding file to create a change' | Select-Object -ExpandProperty 'Sha'
        Send-GitCommit -Credential $bbConnection.Credential
    }
    finally
    {
        Pop-Location
    }
}

function GivenANewBranch
{
    param(
        [string]
        $branchName,
        [string]
        $start
    )
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $branchName -StartPoint $start

}

function GivenANewTag
{
    param(
        [string]    
        $name
    )
    New-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -RepositoryKey $repoName -Name $name -CommitID $commitHash
}

function WhenGettingChanges
{
    [CmdletBinding()]
    param(
        [string]
        $To,
        [string]
        $from
    )   
    $script:changesList = Get-BBServerChange -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $from -To $To
}

function ThenWeShouldGetNoChanges
{
    it 'should not have any changes' {
        $script:changesList | should -BeNullOrEmpty
    }
}

function ThenWeShouldGetChanges
{
    param(
        [string]
        $ExpectedChanges
    )
    it ('should have some changes that match {0}' -f $ExpectedChanges) {
        $script:changesList.path | Where-Object {$_ -match $ExpectedChanges } | should -not -BeNullOrEmpty
    }
}

function ThenItShouldThrowAnError
{
    param(
        [string]
        $ExpectedError
    )
    it 'should throw an error' {
        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -not -BeNullOrEmpty
    }
}

Describe 'Get-BBServerChange.when checking for changes on a branch that does not exist' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    WhenGettingChanges -From 'branchA' -To 'branchIDontExist' -ErrorAction SilentlyContinue
    ThenItShouldThrowAnError -ExpectedError 'does not exist in this repository'
    ThenWeShouldGetNoChanges
}

Describe 'Get-BBServerChange.when checking for changes on two branches we should get changes' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From 'branchA' -To 'branchB'
    ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
}

Describe 'Get-BBServerChange.when checking for changes on a commit we should get changes' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From $script:commitHash -To 'branchB'
    ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
}

Describe 'Get-BBServerChange.when checking for changes on a tag we should get changes' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    GivenANewTag -Name 'testTag'
    WhenGettingChanges -From 'testTag' -To 'branchB'
    ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
}

Describe 'Get-BBServerChange.when checking for changes on a tag with a name that needs encoding we should get changes' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    GivenANewTag -Name 'feature/test+tag.please&Encode'
    WhenGettingChanges -From 'feature/test+tag.please&Encode' -To 'branchB'
    ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
}

Describe 'Get-BBServerChange.when checking for changes on a tag with a name that has invalid characters we should not get changes' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From 'feature/test+tag?please&Encode' -To 'branchB' -ErrorAction SilentlyContinue
    ThenItShouldThrowAnError -ExpectedError 'does not exist in this repository'
    ThenWeShouldGetNoChanges
}

Describe 'Get-BBServerChange.when checking for changes on two branches that are up to date we should get No changes' {
    Init
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From 'branchB' -To 'master'
    ThenWeShouldGetNoChanges 
}
