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
$fromBranchName = 'branch-to-merge'
$toBranchName = 'destination-branch'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerPullRequest Tests'
$pullRequest = $null
$start = 'master'
$receivedPullRequest = $null

function GivenARepository
{   
    $Script:pullRequest = $null
    $getRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName

    if ( $getRepo )
    {
        Remove-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -Force
    }
    New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName | Out-Null
    
    $getBranches = Get-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName
    if( !$getBranches )
    {
        $targetRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName
        $repoClonePath = $targetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $Script:tempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $Script:tempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $Script:tempRepoRoot
        git clone $repoClonePath $repoName 2>&1
        Set-Location $repoName
        git commit --allow-empty -m 'Initializing repository for `Get-BBServerPullRequest` tests' 2>&1
        git push -u origin 2>&1
    }
}

function GivenAPullRequest
{
    param(
        [string]
        $fromBranchName
    )
    try
    {
        git checkout -b $fromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint $Script:start -ErrorAction SilentlyContinue

    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $fromBranchName -To $toBranchName
    if($pullRequest) 
    {
        $Script:pullRequest = $pullRequest
    }
}
function GivenTwoPullRequests
{
    param(
        [string]
        $fromBranchName
    )
    try
    {
        git checkout -b $fromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint $Script:start -ErrorAction SilentlyContinue

    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $fromBranchName -To $toBranchName
    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $fromBranchName -To 'master'
    if($pullRequest) 
    {
        $Script:pullRequest = $pullRequest
    }
}
function GivenNoPullRequests
{
    param(
        [string]
        $fromBranchName
    )
    try
    {
        git checkout -b $fromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint $Script:start -ErrorAction SilentlyContinue
}

function WhenGetPullRequestIsCalled
{
    $Global:Error.clear()
    $Script:receivedPullRequest = Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName
}
function WhenGetPullRequestIsCalledWithId
{
    $Global:Error.clear()
    $Script:receivedPullRequest = Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $Script:pullRequest.id
}
function ThenItShouldReturnAllPullRequests
{
    it 'the response should contain multiple pull requests' {
        $Script:receivedPullRequest.size | Should BeGreaterThan 1
    }
}

function ThenItShouldReturnAPullRequest
{
    it ('the response should contain a pull request with id of {0}' -f $Script:pullRequest.id) {
        $Script:receivedPullRequest.id | should -eq $Script:pullRequest.id
    }
}
function ThenItShouldReturnZeroPullRequests
{
    it 'the response should contain no pull requests' {
        $Script:receivedPullRequest.size | Should Be 0
    }
}

Describe 'Get-BBServerPullRequest.when returning all pull requests from the repository' {
    GivenARepository
    GivenTwoPullRequests -fromBranchName 'firstBranch'
    WhenGetPullRequestIsCalled
    ThenItShouldReturnAllPullRequests
}

Describe 'Get-BBServerPullRequest.when searching for a specific pullrequest' {
    GivenARepository
    GivenAPullRequest -fromBranchName 'branch-to-merge'
    WhenGetPullRequestIsCalledWithId
    ThenItShouldReturnAPullRequest
}

Describe 'Get-BBServerPullRequest.when no pull requests are present' {
    GivenARepository
    GivenNoPullRequests -fromBranchName 'branch-to-merge'
    WhenGetPullRequestIsCalled
    ThenItShouldReturnZeroPullRequests
}
