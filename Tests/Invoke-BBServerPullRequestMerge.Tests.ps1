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

$projectKey = 'GBBSBRANCH'
$repoName = 'repositorywithbranches'
$fromBranchName = 'branch-to-merge'
$toBranchName = 'destination-branch'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Invoke-BBServerPullRequests Tests'
$toBranch = $null
$pullRequest = $null
$tempRepoRoot = $null
$version = $null
$id = $null

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
        Set-location $repoName
        git commit --allow-empty -m 'Initializing repository for `Invoke-BBServerPullRequests` tests' 2>&1
        git push -u origin 2>&1
    }
}

function GivenAPullRequest
{      
    try
    {   
        git checkout -b 'branch-to-merge'
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    $Script:toBranch = New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint 'master' -ErrorAction SilentlyContinue
    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $fromBranchName -To $toBranchName
    if($pullRequest)
    {
        $Script:pullRequest = $pullRequest
        $Script:version = $pullRequest.version
        $Script:id = $pullRequest.id
    }
}
function GivenAPullRequestWithConflicts
{
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $fromBranchName -StartPoint 'master'
        
    try
    {
        git checkout -b 'branch-to-merge'
        new-item .\testfile.txt -type file -value "we want a merge conflixt"
        git add .\testfile.txt
        git commit -m 'test commit'
        git push -u origin HEAD
        git checkout master
        new-item .\testfile.txt -type file -value "this is different and we dont know which we want"
        git add .\testfile.txt
        git commit -m 'breaking commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    $Script:toBranch = New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint 'master' -ErrorAction SilentlyContinue
    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $fromBranchName -To $toBranchName
    if($pullRequest)
    {
        $Script:pullRequest = $pullRequest
        $Script:version = $pullRequest.version
        $Script:id = $pullRequest.id
    }
}
function GivenABadVersionNumber{
    $Script:version = '-1'
}

function GivenABadIdNumber {
    $Script:id = '-1'
}
function WhenThePullRequestIsMerged
{
    $Global:Error.Clear()
    Invoke-BBServerPullRequestMerge -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $Script:id -version $Script:version
}

function  ThenItShouldBeMerged
{
    it ('should be merged into {0}' -f $toBranchName){
        $pullRequestStatus = Get-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $Script:pullRequest.id
        $pullRequestStatus.state | should -match 'merged'
    }
}

function ThenItShouldThrowAnError 
{
    param(
        [string]
        $expectedError
    )
    it 'should throw an error' {
        $Global:Error | Where-Object { $_ -match $expectedError } | Should -not -BeNullOrEmpty
    }
}

Describe 'Invoke-BBServerPullRequestMerge.when merged with bad version number' {
    GivenARepository
    GivenAPullRequest
    GivenABadVersionNumber
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -expectedError 'you are attempting to modify a pull request based on out-of-date information' 
}

Describe 'Invoke-BBServerPullRequestMerge.whentrying to merge an invalid pull request' {
    GivenARepository
    GivenAPullRequest
    GivenABadIdNumber
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -expectedError ('com.atlassian.bitbucket.pull.NoSuchPullRequestException: No pull request exists with ID {0} for this repository ' -f $Script:id )
}

Describe 'Invoke-BBServerPullRequestMerge.when a pull request has a conflict' {
    GivenARepository
    GivenAPullRequestWithConflicts
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -expectedError 'The pull request has conflicts and cannot be merged'
}

Describe 'Invoke-BBServerPullRequestMerge.when a pull request is able to merge' {
    GivenARepository
    GivenAPullRequest
    WhenThePullRequestIsMerged
    ThenItShouldBeMerged
}
