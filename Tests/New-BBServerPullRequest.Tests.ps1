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

$ProjectKey = 'NBBSBRANCH'
$RepoName = 'repositorywithbranches'
$FromBranchName = 'branch-to-merge'
$ToBranchName = 'destination-branch'
$Title = 'pull-request-Title'
$Start = 'master'
$Name = 'tagname'
$BBConnection = New-BBServerTestConnection -ProjectKey $ProjectKey -ProjectName 'New-BBServerBranch Tests'
$TempRepoRoot = $null
$PullRequest = $null

function GivenARepository {   
    $Script:PullRequest = $null
    $getRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName

    if ( $getRepo ) {
        Remove-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName -Force
    }
    New-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName | Out-Null
    
    $getBranches = Get-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName
    if ( !$getBranches ) {
        $targetRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName
        $repoClonePath = $targetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $Script:TempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $Script:TempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $Script:TempRepoRoot
        git clone $repoClonePath $RepoName 2>&1
        Set-Location $RepoName
        git commit --allow-empty -m 'Initializing repository for `New-BBServerPullRequest` tests' 2>&1
        git push -u origin 2>&1
    }
}
function GivenABranchWithCommits {
    try {
        git checkout -b $Script:FromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $ToBranchName -StartPoint $Start -ErrorAction SilentlyContinue
}

function GivenABranchWithNoCommits {        
    try {
        git checkout -b $Script:FromBranchName
        git push -u origin HEAD
    }
    finally {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $Script:ToBranchName -StartPoint $Start -ErrorAction SilentlyContinue
}

function GivenNoDestinationBranchExists {
    try {
        git checkout -b $Script:FromBranchName
        git push -u origin HEAD
    }
    finally {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
}
function GivenATag {
    try {
        git checkout -b $Script:FromBranchName

        git commit --allow-empty -m "testing tag"
        $CommitId = git rev-parse HEAD
        git push -u origin HEAD
    }
    finally {
        Pop-Location
        Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $Script:ToBranchName -StartPoint $Start -ErrorAction SilentlyContinue
    New-BBServerTag -Connection $BBConnection -ProjectKey $ProjectKey -RepositoryKey $RepoName -Name $Name -CommitID $CommitId
}
function GivenNoFromBranchExists {

    Pop-Location
    Remove-Item -Path $Script:TempRepoRoot -Recurse -Force
    New-BBServerBranch -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $Script:ToBranchName -StartPoint $Start -ErrorAction SilentlyContinue
}

function WhenAPullRequestIsCreated {   
    param(
        [String]
        $From
    )
    $Global:Error.clear()
    $PullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -From $From -To $ToBranchName -Title $Title
    if ($PullRequest) {
        $Script:PullRequest = $PullRequest
    }
}

function ThenANewPullRequestShouldBeCreated {
    $PullRequest = Get-BBServerPullRequest  -Connection $BBConnection -ProjectKey $ProjectKey -RepoName $RepoName -id $Script:PullRequest.id
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
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated -From $Script:FromBranchName
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a pull request is created twice' {
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated -From $Script:FromBranchName
    WhenAPullRequestIsCreated -From $Script:FromBranchName
    ThenItShouldThrowAnError -ExpectedError 'Only one pull request may be open for a given source and target branch'
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a branch is up to date' {
    GivenARepository
    GivenABranchWithNoCommits
    WhenAPullRequestIsCreated -From $Script:FromBranchName
    ThenItShouldThrowAnError -ExpectedError 'is already up-to-date with branch'
}

Describe 'New-BBServerPullRequest.when pull request is made with a destination bad branch' {
    GivenARepository
    GivenNoDestinationBranchExists
    WhenAPullRequestIsCreated -From $Script:FromBranchName
    ThenItShouldThrowAnError -ExpectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $RepoName, $ProjectKey, $Script:ToBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a from bad branch' {
    GivenARepository
    GivenNoFromBranchExists
    WhenAPullRequestIsCreated -From $Script:FromBranchName
    ThenItShouldThrowAnError -ExpectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $RepoName, $ProjectKey, $Script:FromBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a tag to a branch' {
    GivenARepository
    GivenATag
    WhenAPullRequestIsCreated -From $Name
    ThenANewPullRequestShouldBeCreated
}