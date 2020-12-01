# Copyright 2016 - 2018 WebMD Health Services
#
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
$failed = $false
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Remove-BBServerTag Tests' 

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'
    $script:failed = $false

    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepositoryWithTaggedCommits
{
    param(
        [Parameter(Mandatory=$true)]
        [String[]]$WithTagNamed
    )

    New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    foreach( $tag in $WithTagNamed )
    {
        $commit = New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection
        New-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -Name $tag -CommitID $commit.Sha -RepositoryKey $repoName
    }
}

function WhenRemovingTags
{
    param(
        [String[]]$Tag
    )

    try 
    {
        Remove-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -RepositoryKey $repoName -TagName $Tag -ErrorAction Stop
    }
    catch
    {
        $script:failed = $true
    }
}

function ThenRepositoryTags
{
    param(
        [String[]]$Tag
    )

    $tags = @( Get-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -RepositoryKey $repoName )
    $actualTagCount = $tags.Count
    $tags = $tags | Select-Object -ExpandProperty 'displayId'
    $expectedTagCount = $Tag.Count

    It ('should have {0} tags in repository' -f $expectedTagCount) {
        $expectedTagCount | Should -BeExactly $actualTagCount
    }
    foreach ( $serverTag in $Tag )
    {
        It ('should have the tag(s) {0}' -f $serverTag) {
            $serverTag | Should -BeIn $tags
        }
    }
}

function ThenShouldFail
{
    It('Should fail') {
        $failed | Should -BeTrue
    }
}

Describe 'Remove-BBServerTag when removing a tag that exists' {
    Init
    GivenARepositoryWithTaggedCommits -WithTagNamed 'one', 'two', 'three'
    WhenRemovingTags 'one', 'three'
    ThenRepositoryTags 'two'
}

Describe 'Remove-BBServerTag when removing a tag that does not exist' {
    Init
    GivenARepositoryWithTaggedCommits -WithTagNamed 'exists'
    WhenRemovingTags 'doesNotExist'
    ThenShouldFail
}