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

$projectKey = 'GBBSCHANGE'
$repoName = 'RepositoryWithChanges'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerChanges Tests' 
$commitHash = $null
function GivenARepositoryWithBranches
{
    [CmdletBinding()]
    param(
        $BranchName
    )
    $script:bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerChanges Tests'
    $repository = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName 
    if($repository)
    {
        Remove-BBServerRepository -Connection $BBConnection -ProjectKey $ProjectKey -Name $RepoName -Force
    }
    New-BBServerRepository -Connection $script:bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null
    $bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerChanges Tests' 
    $targetRepo = Get-BBServerRepository -Connection $script:bbConnection -ProjectKey $projectKey -Name $repoName
    $repoClonePath = $targetRepo.links.clone.href | Where-Object { $_ -match 'http' }
    $tempRepoRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('{0}' -f $RepoName)
    New-Item -Path $tempRepoRoot -ItemType 'Directory' | Out-Null
            
    Push-Location -Path $tempRepoRoot
    try
    {
        git clone $repoClonePath $repoName 2>&1
        cd $repoName
        git commit --allow-empty -m 'Initializing repository for `Get-BBServerChanges` tests' 2>&1
        git push -u origin 2>&1
        git checkout -b $BranchName
        New-Item -Path 'test.txt' -ItemType 'File' -Force
        git add .
        git commit --allow-empty -m 'adding file to create a change' 2>&1
        $script:commitHash = git rev-parse HEAD 2>$null
        git push -u origin $BranchName
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $tempRepoRoot -Recurse -Force
    }
}

function GivenANewBranch
{
    param(
        [string]
        $branchName,
        [string]
        $start
    )
    New-BBServerBranch -Connection $script:bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $branchName -StartPoint $start

}
function WhenGettingChanges
{
    param(
        [string]
        $To,
        [string]
        $from
    )   
    $script:changesList = Get-BBServerChanges -Connection $script:bbConnection -ProjectKey $projectKey -RepoName $repoName -From $from -To $To
}

function ThenWeShouldGetNoChanges
{
    it 'should not have any changes' {
        $script:changesList | should -BeNullOrEmpty
    }
}

function ThenWeShouldGetChanges
{
    param(
        [string]
        $ExpectedChanges
    )
    it ('should have some changes that match {0}' -f $ExpectedChanges) {
        $script:changesList.path | Where-Object {$_ -match $ExpectedChanges } | should -not -BeNullOrEmpty
    }
}

function ThenItShouldThrowAnError
{
    param(
        [string]
        $ExpectedError
    )
    it 'should throw an error' {
        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -not -BeNullOrEmpty
    }
}

Describe 'Get-BBServerChanges.when checking for changes on a branch that does not exist' {
    GivenARepositoryWithBranches -branchName 'branchA'
    WhenGettingChanges -From 'branchA' -To 'branchIDontExist'
    ThenItShouldThrowAnError -ExpectedError 'does not exist in this repository'
    ThenWeShouldGetNoChanges
}

Describe 'Get-BBServerChanges.when checking for changes on two branches we should get changes' {
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From 'branchA' -To 'branchB'
    ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
}

Describe 'Get-BBServerChanges.when checking for changes on a commit we should get changes' {
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From $script:commitHash -To 'branchB'
    ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
}

Describe 'Get-BBServerChanges.when checking for changes on two branches that are up to date we should get No changes' {
    GivenARepositoryWithBranches -branchName 'branchA'
    GivenANewBranch -branchName 'branchB' -start 'master'
    WhenGettingChanges -From 'branchB' -To 'master'
    ThenWeShouldGetNoChanges 
}
