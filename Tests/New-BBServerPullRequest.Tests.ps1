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

$projectKey = 'NBBSBRANCH'
$repoName = 'repositorywithbranches'
$fromBranchName = 'branch-to-merge'
$toBranchName = 'destination-branch'
$start = 'master'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerBranch Tests'
$tempRepoRoot = $null
$pullRequest = $null

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
        $script:tempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $script:tempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $script:tempRepoRoot
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
        git checkout -b $script:fromBranchName
        git commit --allow-empty -m 'test commit'
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $toBranchName -StartPoint $start -ErrorAction SilentlyContinue
}

function GivenABranchWithNoCommits
{        
    try
    {
        git checkout -b $script:fromBranchName
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $script:tempRepoRoot -Recurse -Force
    }
    New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $script:toBranchName -StartPoint $start -ErrorAction SilentlyContinue
}

function GivenNoDestinationBranchExists
{
    try
    {
        git checkout -b $script:fromBranchName
        git push -u origin HEAD
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $script:tempRepoRoot -Recurse -Force
    }
}

function GivenNoFromBranchExists
{
        Pop-Location
        Remove-Item -Path $script:tempRepoRoot -Recurse -Force
        New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $script:toBranchName -StartPoint $start -ErrorAction SilentlyContinue
}

function WhenAPullRequestIsCreated 
{   
    $Global:Error.clear()
    $pullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $script:fromBranchName -To $toBranchName
    if($pullRequest) 
    {
        $Script:pullRequest = $pullRequest
    }
}

function ThenANewPullRequestShouldBeCreated 
{
    it 'should not be null' {
        $pullRequest = Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $Script:pullRequest.id
        $pullRequest | Should Not BeNullOrEmpty
    }
}
function ThenItShouldThrowAnError 
{
    param(
        [string]
        $expectedError
    )
    it 'should throw an error' {
        write-host $Global:Error
        Write-Host $expectedError 
        $Global:Error | Where-Object { $_ -match $expectedError } | Should -not -BeNullOrEmpty
    }
}

Describe 'New-BBServerPullRequest.when a pull request is created' {
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a pull request is created twice' {
    GivenARepository
    GivenABranchWithCommits
    WhenAPullRequestIsCreated
    WhenAPullRequestIsCreated
    ThenItShouldThrowAnError -expectedError 'Only one pull request may be open for a given source and target branch'
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a branch is up to date' {
    GivenARepository
    GivenABranchWithNoCommits
    WhenAPullRequestIsCreated
    ThenItShouldThrowAnError -expectedError 'is already up-to-date with branch'
}

Describe 'New-BBServerPullRequest.when pull request is made with a destination bad branch' {
    GivenARepository
    GivenNoDestinationBranchExists
    WhenAPullRequestIsCreated 
    ThenItShouldThrowAnError -expectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $repoName, $projectKey, $script:toBranchName)
}

Describe 'New-BBServerPullRequest.when pull request is made with a from bad branch' {
    GivenARepository
    GivenNoFromBranchExists
    WhenAPullRequestIsCreated 
    ThenItShouldThrowAnError -expectedError ('Repository "{0}" of project with key "{1}" has no branch "{2}"' -f $repoName, $projectKey, $script:fromBranchName)
}