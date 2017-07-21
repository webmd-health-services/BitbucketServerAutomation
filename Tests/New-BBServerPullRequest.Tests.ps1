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
$repoName = 'BasicRepository'
$BranchName = 'branchToMerge'
$StartingPoint = 'testStart'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerBranch Tests'
$newBranch = $null
if ( $getRepo )
{
    Remove-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -Force
}
New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName | Out-Null

function GivenABranch {
    $script:newBranch = New-BBServerBranch -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -BranchName $BranchName -StartPoint $StartPoint -ErrorAction SilentlyContinue
    
}

function WhenAPullRequestIsCreated {
    $newPullRequest = New-BBServerPullRequest -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -From $BranchName -To $destinationBranch
}

function ThenANewPullRequestShouldBeCreated {
    it 'should not be null' {
        $pullRequest = Get-BBServerPullRequest

        $pullRequest | Should Not BeNullOrEmpty
    }
    it 'should be mergable' {

    }
}
function ThenThereShouldOnlyBeOne {
    it 'should only have one pull request' {

    }
}
function ThenNoPullRequestShouldBeCreated {
    it 'should be null' {
        $pr = Get-BBServerPullRequest
        $pr | should BeNullOrEmpty
    }
}

Describe 'New-BBServerPullRequest.when a pull request is created' {
    GivenABranch
    WhenAPullRequestIsCreated
    ThenANewPullRequestShouldBeCreated
}

Describe 'New-BBServerPullRequest.when a pull request is created twice' {
    GivenABranch
    WhenAPullRequestIsCreated
    WhenAPullRequestIsCreated
    ThenANewPullRequestShouldBeCreated
    ThenThereShouldOnlyBeOne
}

Describe 'New-BBServerPullRequest.when a pull request is unmergable' {
    GivenABranch
    WhenAPullRequestIsCreated
    ThenNoPullRequestShouldBeCreated
}