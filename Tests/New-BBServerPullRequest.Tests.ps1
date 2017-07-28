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

$projectKey = 'NBBSBRANCH'
$repoName = 'repositorywithbranches'
$fromBranchName = 'branch-to-merge'
$BadFromBranchName = 'this-shouldnt-work'
$toBranchName = 'destination-branch'
$title = 'pull-request-title'
$start = 'master'
$Name = 'tagname'
$BBConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerBranch Tests'
$tempRepoRoot = $null
$pullRequest = $null

function GivenARepository
{   
    $Script:pullRequest = $null
    $getRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $projectKey -Name $repoName

    if ( $getRepo )
    {
        Remove-BBServerRepository -Connection $BBConnection -ProjectKey $projectKey -Name $repoName -Force
    }
    New-BBServerRepository -Connection $BBConnection -ProjectKey $projectKey -Name $repoName | Out-Null
    
    $getBranches = Get-BBServerBranch -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName
    if( !$getBranches )
    {
        $targetRepo = Get-BBServerRepository -Connection $BBConnection -ProjectKey $projectKey -Name $repoName
        $repoClonePath = $targetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $Script:tempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $Script:tempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $Script:tempRepoRoot
        git clone $repoClonePath $repoName 2>&1
        Set-Location $repoName
        git commit --allow-empty -m 'Initializing repository for `New-BBServerPullRequest` tests' 2>&1
        git push -u origin 2>&1
    }
}
function GivenABranchWithCommits
{
   try
    {
        git checkout -b $Script:fromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint $start -ErrorAction SilentlyContinue
}

function GivenABranchWithNoCommits
{        
    try
    {
        git checkout -b $Script:fromBranchName
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $Script:toBranchName -StartPoint $start -ErrorAction SilentlyContinue
}

function GivenNoDestinationBranchExists
{
    try
    {
        git checkout -b $Script:fromBranchName
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
}
function GivenATag
{
    try
    {
        git checkout -b $Script:fromBranchName

        git commit --allow-empty -m "testing tag"
        $CommitId = git rev-parse HEAD
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $Script:toBranchName -StartPoint $start -ErrorAction SilentlyContinue
    New-BBServerTag -Connection $BBConnection -ProjectKey $ProjectKey -RepositoryKey $RepoName -Name $Name -CommitID $CommitId
}
function GivenNoFromBranchExists
{

        Pop-Location
        Remove-Item -Path $Script:tempRepoRoot -Recurse -Force
        New-BBServerBranch -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $Script:toBranchName -StartPoint $start -ErrorAction SilentlyContinue
}

function WhenAPullRequestIsCreated 
{   
    param(
        [String]
        $From
    )
    $Global:Error.clear()
    $pullRequest = New-BBServerPullRequest -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName -From $From -To $toBranchName -Title $title
    if($pullRequest) 
    {
        $Script:pullRequest = $pullRequest
    }
}

function ThenANewPullRequestShouldBeCreated 
{
    $pullRequest = Get-BBServerPullRequest  -Connection $BBConnection -ProjectKey $projectKey -RepoName $repoName -id $Script:pullRequest.id
    it 'should not be null' {
        $pullRequest | Should Not BeNullOrEmpty
    }
    it 'should match the expected title' {
        $pullRequest.title | Should Not BeNullOrEmpty
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

Describe 'New-BBServerPullRequest.when a pull request is created' {
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a pull request is created twice' {
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -expectedError 'Only one pull request may be open for a given source and target branch'
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a branch is up to date' {
    GivenARepository
    GivenABranchWithNoCommits
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -expectedError 'is already up-to-date with branch'
}

Describe 'New-BBServerPullRequest.when pull request is made with a destination bad branch' {
    GivenARepository
    GivenNoDestinationBranchExists
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -expectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $repoName, $projectKey, $Script:toBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a from bad branch' {
    GivenARepository
    GivenNoFromBranchExists
    WhenAPullRequestIsCreated -From $Script:fromBranchName
    ThenItShouldThrowAnError -expectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $repoName, $projectKey, $Script:fromBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a tag to a branch' {
    GivenARepository
    GivenATag
    WhenAPullRequestIsCreated -From $name
    ThenANewPullRequestShouldBeCreated
}