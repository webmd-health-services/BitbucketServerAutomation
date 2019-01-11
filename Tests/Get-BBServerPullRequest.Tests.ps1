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

$ProjectKey = 'GBBSPR'
$repo = $null
$repoName = $null
$repoRoot = $null
$FromBranchName = 'branch-to-merge'
$ToBranchName = 'destination-branch'
$bbConnection = New-BBServerTestConnection -ProjectKey $ProjectKey -ProjectName 'Get-BBServerPullRequest Tests'
$pullRequest = $null
$Start = 'master'
$Title = 'Pull Request Title'
$ReceivedPullRequest = $null

function Init
{
    $script:pullRequest = $null
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepository
{
    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection
}

function GivenBranch
{
    param(
        $BranchName
    )

    New-GitBranch -Name $BranchName -RepoRoot $repoRoot
    Update-GitRepository -Revision $BranchName -RepoRoot $repoRoot

    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection
}

function GivenAPullRequest
{
    param(
        [string]
        $FromBranchName
    )

    New-BBServerBranch -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -BranchName $ToBranchName -StartPoint $Script:Start -ErrorAction SilentlyContinue

    $PullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -From $FromBranchName -To $ToBranchName -Title $Title
    if($PullRequest)
    {
        $Script:PullRequest = $PullRequest
    }
}
function GivenTwoPullRequests
{
    param(
        [string]
        $FromBranchName
    )

    New-BBServerBranch -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -BranchName $ToBranchName -StartPoint $Script:Start -ErrorAction SilentlyContinue

    $PullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -From $FromBranchName -To $ToBranchName -Title $Title
    $PullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -From $FromBranchName -To 'master' -Title $Title
    if($PullRequest)
    {
        $Script:PullRequest = $PullRequest
    }
}
function GivenNoPullRequests
{
    param(
        [string]
        $FromBranchName
    )

    New-BBServerBranch -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -BranchName $ToBranchName -StartPoint $Script:Start -ErrorAction SilentlyContinue
}

function WhenGetPullRequestIsCalled
{
    $Global:Error.clear()
    $Script:ReceivedPullRequest = Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName
}
function WhenGetPullRequestIsCalledWithId
{
    $Global:Error.clear()
    $Script:ReceivedPullRequest = Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $ProjectKey -RepoName $repoName -id $Script:PullRequest.id
}
function ThenItShouldReturnAllPullRequests
{
    it 'the response should contain multiple pull requests' {
        $Script:ReceivedPullRequest.size | Should BeGreaterThan 1
    }
}

function ThenItShouldReturnAPullRequest
{
    it ('the response should contain a pull request with id of {0}' -f $Script:PullRequest.id) {
        $Script:ReceivedPullRequest.id | Should -eq $Script:PullRequest.id
    }
}
function ThenItShouldReturnZeroPullRequests
{
    it 'the response should contain no pull requests' {
        $Script:ReceivedPullRequest.size | Should Be 0
    }
}

Describe 'Get-BBServerPullRequest.when returning all pull requests from the repository' {
    Init
    GivenARepository
    GivenBranch 'firstBranch'
    GivenTwoPullRequests -fromBranchName 'firstBranch'
    WhenGetPullRequestIsCalled
    ThenItShouldReturnAllPullRequests
}

Describe 'Get-BBServerPullRequest.when searching for a specific pullrequest' {
    Init
    GivenARepository
    GivenBranch 'branch-to-merge'
    GivenAPullRequest -fromBranchName 'branch-to-merge'
    WhenGetPullRequestIsCalledWithId
    ThenItShouldReturnAPullRequest
}

Describe 'Get-BBServerPullRequest.when no pull requests are present' {
    Init
    GivenARepository
    GivenBranch 'branch-to-merge'
    GivenNoPullRequests -fromBranchName 'branch-to-merge'
    WhenGetPullRequestIsCalled
    ThenItShouldReturnZeroPullRequests
}
