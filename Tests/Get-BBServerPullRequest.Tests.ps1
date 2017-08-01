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

$ProjectKey = 'GBBSBRANCH'
$RepoName = 'RepositoryWithBranches'
$FromBranchName = 'branch-to-merge'
$ToBranchName = 'destination-branch'
$BBConnection = New-BBServerTestConnection -ProjectKey $ProjectKey -ProjectName 'Get-BBServerPullRequest Tests'
$PullRequest = $null
$Start = 'master'
$Title = 'Pull Request Title'
$ReceivedPullRequest = $null

function GivenARepository
{   
    $Script:PullRequest = $null
    $GetRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName

    if ( $GetRepo )
    {
        Remove-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName -Force
    }
    New-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName | Out-Null
    
    $GetBranches = Get-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName
    if( !$GetBranches )
    {
        $TargetRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName
        $repoClonePath = $TargetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $Script:TempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $Script:TempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $Script:TempRepoRoot
        git clone $repoClonePath $RepoName 2>&1
        Set-Location $RepoName
        git commit --allow-empty -m 'Initializing repository for `Get-BBServerPullRequest` tests' 2>&1
        git push -u origin 2>&1
    }
}

function GivenAPullRequest
{
    param(
        [string]
        $FromBranchName
    )
    try
    {
        git checkout -b $FromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint $Script:Start -ErrorAction SilentlyContinue

    $PullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -From $FromBranchName -To $ToBranchName -Title $Title
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
    try
    {
        git checkout -b $FromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint $Script:Start -ErrorAction SilentlyContinue

    $PullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -From $FromBranchName -To $ToBranchName -Title $Title
    $PullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -From $FromBranchName -To 'master' -Title $Title
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
    try
    {
        git checkout -b $FromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint $Script:Start -ErrorAction SilentlyContinue
}

function WhenGetPullRequestIsCalled
{
    $Global:Error.clear()
    $Script:ReceivedPullRequest = Get-BBServerPullRequest  -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName
}
function WhenGetPullRequestIsCalledWithId
{
    $Global:Error.clear()
    $Script:ReceivedPullRequest = Get-BBServerPullRequest  -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -id $Script:PullRequest.id
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
