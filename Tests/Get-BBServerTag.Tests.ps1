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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'GBBSTAG'
$repo = $null
$repoName = $null
$repoRoot = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerTag Tests' 

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepositoryWithTaggedCommits
{
    param(
        [Int]
        $WithNumberOfTags,

        [String]
        $WithTagNamed
    )

    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    if( $WithTagNamed )
    {
        $commit = New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection
        New-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -Name $WithTagNamed -CommitID $commit.Sha -RepositoryKey $repoName
    }
}

function WhenGettingTags
{
    return Get-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -RepositoryKey $repoName
}

function ThenTagsShouldBeObtained
{
    param(
        [Object]
        $WithTags,

        [Int]
        $NumberOfTags,

        [String]
        $WithTagNamed
    )
    if( $WithTagNamed )
    {
        It ('should have named the tag {0}' -f $WithTagNamed) {
            $WithTags[0].displayId | should Be $WithTagNamed
        }
    }
    else
    {
        It ('should get {0} tags' -f $NumberOfTags) {
            $WithTags.Count | should Be $NumberOfTags
        }
        
    }
}

Describe 'Get-BBServerTag when getting the most recent tag' {
    Init
    $tagName ="thisIsTheMostRecentTag"
    GivenARepositoryWithTaggedCommits -WithTagNamed $tagName
    $tags = WhenGettingTags
    ThenTagsShouldBeObtained -WithTags $tags -NumberOfTags 1 -WithTagNamed $tagName
}
