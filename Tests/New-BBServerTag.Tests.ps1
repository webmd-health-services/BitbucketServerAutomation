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

$projectKey = 'NBBSTAG'
$repo = $null
$repoName = $null
$repoRoot = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerTag Tests'

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenAValidCommit
{
    $commit = New-TestRepoCommit -RepoRoot $repoRoot -Connection $bbConnection

    return $commit.Sha
}

function WhenTaggingTheCommit
{
    [CmdletBinding()]
    param(
        [String]
        $CommitHash,

        [String]
        $TagName,

        [String]
        $Message,

        [Switch]
        $Force,

        [String]
        $Type
    )

    $optionalParams = @{}
    if($Message)
    {
        $optionalParams['Message'] = $Message
    }
    if($Force)
    {
        $optionalParams['Force'] = $true
    }
    if($Type)
    {
        $optionalParams['Type'] = $Type
    }

    $Global:Error.Clear()

    New-BBServerTag -Connection $bbConnection -ProjectKey $projectKey -RepositoryKey $repoName -name $TagName -CommitID $commitHash @optionalParams
}

function ThenTheCommitShouldBeTagged
{
    param(
        [String]
        $TagName,

        [String]
        $CommitHash
    )

    $tag = Get-BBServerTag -ProjectKey $projectKey -RepositoryKey $repoName -Connection $bbConnection | Where-Object { $_.displayId -eq $TagName }

    it ('should apply the {0} tag to commit {1} in the remote repo' -f $TagName, $CommitHash) {
        $tag | Should -Not -BeNullOrEmpty
        $tag.latestCommit | Should -Be $CommitHash
    }
}

function ThenTagShouldNotExist
{
    param(
        [string]
        $TagName
    )

    $tag = Get-BBServerTag -ProjectKey $projectKey -RepositoryKey $repoName -Connection $bbConnection | Where-Object { $_.displayId -eq $TagName }

    it ('should not apply the {0} tag' -f $TagName) {
        $tag | Should -BeNullOrEmpty
    }
}

function ThenError
{
    param(
        $ExpectedError
    )

    it 'should throw errors' {
        $Global:Error[0] | Should -Match 'Unable to tag commit'
        $Global:Error[1] | Should -Match $ExpectedError
    }
}

function ThenNoErrors
{
    It 'should not write any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'New-BBServerTag.when tagging a new commit' {
    Init
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagName $tagName -CommitHash $commit
    ThenNoErrors
}

Describe 'New-BBServerTag.when tagging an invalid commit' {
    Init
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = 'notactuallyacommithash'
    WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage -ErrorAction SilentlyContinue
    ThenTagShouldNotExist $tagName
    ThenError ("'{0}' is an invalid tag point." -f $commit)
}

Describe 'New-BBServerTag.when re-tagging a new commit that already has a tag' {
    Init
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $commit -TagName 'v1.4' -Message $tagMessage
    WhenTaggingTheCommit -CommitHash $commit -TagName 'v1.5' -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagName 'v1.5' -CommitHash $commit
    ThenNoErrors
}

Describe 'New-BBServerTag.when tagging two commits with the same tag' {
    Init
    $tagMessage = 'message'
    $tagName = 'v1.4'
    $firstcommit = GivenAValidCommit
    $secondcommit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $firstcommit -TagName $tagName -Message $tagMessage
    WhenTaggingTheCommit -CommitHash $secondcommit -TagName $tagName -Message $tagMessage -ErrorAction SilentlyContinue
    ThenTheCommitShouldBeTagged -TagName $tagName -CommitHash $firstcommit
    ThenError ("Tag '{0}' already exists in repository" -f $tagName)
}

Describe 'New-BBServerTag.when tagging two commits with the same tag and including the Force switch' {
    Init
    $tagMessage = 'message'
    $tagName = 'v1.4'
    $firstcommit = GivenAValidCommit
    $secondcommit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $firstcommit -TagName $tagName -Message $tagMessage
    WhenTaggingTheCommit -CommitHash $secondcommit -TagName $tagName -Message $tagMessage -Force
    ThenTheCommitShouldBeTagged -TagName $tagName -CommitHash $secondcommit
    ThenNoErrors
}

Describe 'New-BBServerTag.when tagging a new commit with an Annotated Tag' {
    Init
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage -Type 'ANNOTATED' -Force
    ThenTheCommitShouldBeTagged -TagName $tagName -CommitHash $commit
    ThenNoErrors
}

Describe 'New-BBServerTag.when tagging a new commit with an Invalid Tag type' {
    Init
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage -Type 'INVALID' -ErrorAction SilentlyContinue
    ThenTagShouldNotExist $tagName
    ThenError 'An error occurred while processing the request. Check the server logs for more information.'
}
