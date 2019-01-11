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

$projectKey = 'NBBSPR'
$repo = $null
$repoRoot = $null
$repoName = $null
$fromBranchName = 'branch-to-merge'
$toBranchName = 'destination-branch'
$start = 'master'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerPullRequest Tests'
$pullRequest = $null

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'
    $script:pullRequest = $null

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepository
{
    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection
}

function GivenABranchWithCommits
{
    New-GitBranch -Name $fromBranchName -RepoRoot $repoRoot
    Update-GitRepository -Revision $fromBranchName -RepoRoot $repoRoot
    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint $Start -ErrorAction SilentlyContinue
}

function GivenABranchWithNoCommits
{
    New-GitBranch -Name $fromBranchName -RepoRoot $repoRoot
    Update-GitRepository -Revision $fromBranchName -RepoRoot $repoRoot
    Send-GitCommit -RepoRoot $repoRoot -Credential $bbConnection.Credential
    
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $Script:ToBranchName -StartPoint $Start -ErrorAction SilentlyContinue
}

function GivenNoDestinationBranchExists
{
    New-GitBranch -Name $fromBranchName -RepoRoot $repoRoot
    Update-GitRepository -Revision $fromBranchName -RepoRoot $repoRoot
    Send-GitCommit -RepoRoot $repoRoot -Credential $bbConnection.Credential
}

function GivenATag
{
    param(
        $Name
    )

    New-GitBranch -Name $fromBranchName -RepoRoot $repoRoot
    Update-GitRepository -Revision $fromBranchName -RepoRoot $repoRoot
    $commit = New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $Script:ToBranchName -StartPoint $Start -ErrorAction SilentlyContinue
    New-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -RepositoryKey $repoName -Name $Name -CommitID $commit.Sha
}
function GivenNoFromBranchExists
{
}

function WhenAPullRequestIsCreated {
    param(
        [String]
        $From
    )
    $Global:Error.clear()
    $PullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $From -To $toBranchName -Title 'Pull Request Title' -ErrorAction SilentlyContinue
    if ($PullRequest) {
        $Script:PullRequest = $PullRequest
    }
}

function ThenANewPullRequestShouldBeCreated {
    $PullRequest = Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $Script:PullRequest.id
    it 'should not be null' {
        $PullRequest | Should Not BeNullOrEmpty
    }
    it 'should match the expected Title' {
        $PullRequest.Title | Should Not BeNullOrEmpty
    }
}
function ThenItShouldThrowAnError {
    param(
        [string]
        $ExpectedError
    )
    it 'should throw an error' {
        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -not -BeNullOrEmpty
    }
}

Describe 'New-BBServerPullRequest.when a pull request is created' {
    Init
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a pull request is created twice' {
    Init
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -ExpectedError 'Only one pull request may be open for a given source and target branch'
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a branch is up to date' {
    Init
    GivenARepository
    GivenABranchWithNoCommits
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -ExpectedError 'is already up-to-date with branch'
}

Describe 'New-BBServerPullRequest.when pull request is made with a destination bad branch' {
    Init
    GivenARepository
    GivenNoDestinationBranchExists
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -ExpectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $repoName, $projectKey, $Script:ToBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a from bad branch' {
    Init
    GivenARepository
    GivenNoFromBranchExists
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -ExpectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $repoName, $projectKey, $Script:fromBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a tag to a branch' {
    Init
    GivenARepository
    GivenATag 'tagname'
    WhenAPullRequestIsCreated -From 'tagname'
    ThenANewPullRequestShouldBeCreated
}