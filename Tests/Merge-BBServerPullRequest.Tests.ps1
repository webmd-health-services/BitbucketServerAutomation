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

Set-StrictMode -Version 'Latest'
#Requires -Version 5.1

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'MBBSPR'
$repo = $null
$repoRoot = $null
$repoName = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Merge-BBServerPullRequests Tests'
$fromBranchName = 'branch-to-merge'
$toBranchName = 'destination-branch'
$toBranch = $null
$version = $null
$iD = $null
$title = 'Pull Request Title'

function Init
{
    $script:toBranch = $null
    $script:version = $null
    $script:iD = $null
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'
    $script:tempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath $repoName

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepository
{
    New-TestRepoCommit -RepoRoot $tempRepoRoot -Connection $bbConnection
}

function GivenAPullRequest
{
    New-GitBranch -Name $fromBranchName -RepoRoot $tempRepoRoot
    Update-GitRepository -Revision $fromBranchName -RepoRoot $tempRepoRoot
    New-TestRepoCommit -RepoRoot $tempRepoRoot -Connection $bbConnection

    $Script:ToBranch = New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint 'master' -ErrorAction SilentlyContinue
    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -From $FromBranchName -To $ToBranchName -Title $Title
    if ($pullRequest) {
        $Script:Version = $pullRequest.version
        $Script:ID = $pullRequest.id
    }
    else {
        $Script:Version = -1
        $Script:ID = -1
    }
}
function GivenAPullRequestWithConflicts {
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -BranchName $FromBranchName -StartPoint 'master'

    Push-Location -Path $tempRepoRoot
    try
    {
        New-GitBranch -Name $fromBranchName
        Update-GitRepository -Revision $fromBranchName
        New-Item .\testfile.txt -type file -value "we want a merge conflixt"
        Add-GitItem -Path '.\testfile.txt'
        Save-GitCommit -Message 'test commit'
        Send-GitCommit -Credential $bbConnection.Credential

        Update-GitRepository -Revision 'master'
        New-Item .\testfile.txt -type file -value "this is different and we dont know which we want"
        Add-GitItem -Path '.\testfile.txt'
        Save-GitCommit -Message 'breaking commit'
        Send-GitCommit -Credential $bbConnection.Credential
    }
    finally
    {
        Pop-Location
    }

    $Script:ToBranch = New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint 'master' -ErrorAction SilentlyContinue
    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -From $FromBranchName -To $ToBranchName -Title $Title
    if ($pullRequest) {
        $Script:Version = $pullRequest.version
        $Script:ID = $pullRequest.id
    }
    else {
        $Script:Version = -1
        $Script:ID = -1
    }
}
function GivenABadVersionNumber {
    $Script:Version = '-1'
}

function GivenABadIdNumber {
    $Script:ID = '-1'
}
function WhenThePullRequestIsMerged {
    $Global:Error.Clear()
    Merge-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -id $Script:ID -Version $Script:Version -ErrorAction SilentlyContinue
}

function  ThenItShouldBeMerged {
    it ('should be merged into {0}' -f $ToBranchName) {
        $pullRequestStatus = Get-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $RepoName -id $Script:ID
        $pullRequestStatus.state | should -match 'merged'
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

Describe 'Merge-BBServerPullRequestMerge.when merged with bad Version number' {
    Init
    GivenARepository
    GivenAPullRequest
    GivenABadVersionNumber
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -ExpectedError 'you are attempting to modify a pull request based on out-of-date information'
}

Describe 'Merge-BBServerPullRequestMerge.whentrying to merge an invalid pull request' {
    Init
    GivenARepository
    GivenAPullRequest
    GivenABadIdNumber
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -ExpectedError ('com.atlassian.bitbucket.pull.NoSuchPullRequestException: No pull request exists with ID {0} for this repository ' -f $Script:ID )
}

Describe 'Merge-BBServerPullRequestMerge.when a pull request has a conflict' {
    Init
    GivenARepository
    GivenAPullRequestWithConflicts
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -ExpectedError 'The pull request has conflicts and cannot be merged'
}

Describe 'Merge-BBServerPullRequestMerge.when a pull request is able to merge' {
    Init
    GivenARepository
    GivenAPullRequest
    WhenThePullRequestIsMerged
    ThenItShouldBeMerged
}
