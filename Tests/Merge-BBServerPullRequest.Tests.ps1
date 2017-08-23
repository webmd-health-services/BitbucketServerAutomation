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
Set-StrictMode -Version 'Latest'

$ProjectKey = 'MBBSPR'
$RepoName = 'repositorywithbranches'
$FromBranchName = 'branch-to-merge'
$ToBranchName = 'destination-branch'
$BBConnection = New-BBServerTestConnection -ProjectKey $ProjectKey -ProjectName 'Merge-BBServerPullRequests Tests'
$ToBranch = $null
$TempRepoRoot = $null
$Version = $null
$ID = $null
$Title = 'Pull Request Title'

function GivenARepository {   
    $Script:pullRequest = $null
    $GetRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName

    if ( $GetRepo ) {
        Remove-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName -Force
    }
    New-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName | Out-Null
    
    $GetBranches = Get-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName
    if ( !$GetBranches ) {
        $TargetRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName
        $RepoClonePath = $TargetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $Script:TempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $Script:TempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $Script:TempRepoRoot
        git clone $RepoClonePath $RepoName 2>&1
        Set-location $RepoName
        git commit --allow-empty -m 'Initializing repository for `Merge-BBServerPullRequests` tests' 2>&1
        git push -u origin 2>&1
    }
}

function GivenAPullRequest {      
    try {   
        git checkout -b 'branch-to-merge'
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    $Script:ToBranch = New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint 'master' -ErrorAction SilentlyContinue
    $pullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -From $FromBranchName -To $ToBranchName -Title $Title
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
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $FromBranchName -StartPoint 'master'
        
    try {
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
    finally {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    $Script:ToBranch = New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint 'master' -ErrorAction SilentlyContinue
    $pullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -From $FromBranchName -To $ToBranchName -Title $Title
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
    Merge-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -id $Script:ID -Version $Script:Version
}

function  ThenItShouldBeMerged {
    it ('should be merged into {0}' -f $ToBranchName) {
        $pullRequestStatus = Get-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -id $Script:ID
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
    GivenARepository
    GivenAPullRequest
    GivenABadVersionNumber
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -ExpectedError 'you are attempting to modify a pull request based on out-of-date information' 
}

Describe 'Merge-BBServerPullRequestMerge.whentrying to merge an invalid pull request' {
    GivenARepository
    GivenAPullRequest
    GivenABadIdNumber
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -ExpectedError ('com.atlassian.bitbucket.pull.NoSuchPullRequestException: No pull request exists with ID {0} for this repository ' -f $Script:ID )
}

Describe 'Merge-BBServerPullRequestMerge.when a pull request has a conflict' {
    GivenARepository
    GivenAPullRequestWithConflicts
    WhenThePullRequestIsMerged
    ThenItShouldThrowAnError -ExpectedError 'The pull request has conflicts and cannot be merged'
}

Describe 'Merge-BBServerPullRequestMerge.when a pull request is able to merge' {
    GivenARepository
    GivenAPullRequest
    WhenThePullRequestIsMerged
    ThenItShouldBeMerged
}
