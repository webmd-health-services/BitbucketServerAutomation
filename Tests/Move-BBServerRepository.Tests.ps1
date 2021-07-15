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

$sourceProjectKey = 'SMOVEBBSR'
$targetProjectKey = 'TMOVEBBSR'
$repoName = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $sourceProjectKey -ProjectName 'Move-BBServerRepository Tests - Source'

function Init
{
    $script:repoName = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $sourceProjectKey | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $sourceProjectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenASourceProject
{
    [CmdletBinding()]
    param(
        [string]
        $ProjectKey,

        [string]
        $WithRepo
    )

    $getRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $ProjectKey -Name $WithRepo -ErrorAction Ignore
    if ( !$getRepo )
    {
        New-BBServerRepository -Connection $bbConnection -ProjectKey $ProjectKey -Name $WithRepo | Out-Null
    }
}

function GivenATargetProject
{
    [CmdletBinding()]
    param(
        [string]
        $ProjectKey,

        [string]
        $WithNoRepo,

        [string]
        $WithRepo
    )

    if( $WithNoRepo )
    {
        $getRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $ProjectKey -Name $WithNoRepo -ErrorAction Ignore
        if ( $getRepo )
        {
            Remove-BBServerRepository -Connection $bbConnection -ProjectKey $ProjectKey -Name $WithNoRepo -Force
        }
    }
    
    $getProject = Get-BBServerProject -Connection $bbConnection -Name 'Move-BBServerRepository Tests - Target' -ErrorAction Ignore
    if ( !$getProject )
    {
        New-BBServerProject -Connection $bbConnection -Key $ProjectKey -Name 'Move-BBServerRepository Tests - Target'
    }

    if( $WithRepo )
    {
        $getRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $ProjectKey -Name $WithRepo -ErrorAction Ignore
        if ( !$getRepo )
        {
            New-BBServerRepository -Connection $bbConnection -ProjectKey $ProjectKey -Name $WithRepo | Out-Null
        }
    }
}

function WhenMovingRepositoryBetweenProjects
{
    [CmdletBinding()]
    param(
        [string]
        $SourceProjectKey,

        [string]
        $TargetProjectKey,

        [string]
        $Repo
    )

    $Global:Error.Clear()

    $moveBBServerRepo = Move-BBServerRepository -Connection $bbConnection -ProjectKey $SourceProjectKey -RepoName $Repo -TargetProjectKey $TargetProjectKey -ErrorAction SilentlyContinue
}

function ThenErrors
{
    [CmdletBinding()]
    param(
        [switch]
        $ShouldNotBeThrown,

        [string]
        $ShouldBeThrown
    )

    if( $ShouldNotBeThrown )
    {
        It 'should not throw any errors' {
            $Global:Error | Should BeNullOrEmpty
        }
    }

    if( $ShouldBeThrown )
    {
        It ('should throw an error: ''{0}''' -f $ShouldBeThrown) {
            $Global:Error | Should Match $ShouldBeThrown
        }
    }
}

function ThenRepositoryShouldHaveMoved
{
    [CmdletBinding()]
    param(
    )

    It 'the specified repository should exist in the target project' {
        Get-BBServerRepository -Connection $bbConnection -ProjectKey $targetProjectKey -Name $repoName | Should Not BeNullOrEmpty
    }

    It 'the specified repository should no longer exist in the original project' {
        Get-BBServerRepository -Connection $bbConnection -ProjectKey $sourceProjectKey -Name $repoName -ErrorAction Ignore | Should BeNullOrEmpty
    }
}

function ThenRepositoryShouldNotHaveMoved
{
    [CmdletBinding()]
    param(
    )

    It 'the specified repository should still exist in the original project' {
        Get-BBServerRepository -Connection $bbConnection -ProjectKey $sourceProjectKey -Name $repoName -ErrorAction Ignore | Should Not BeNullOrEmpty
    }
}

Describe 'Move-BBServerRepository.when moving a repository between two projects' {
    Init
    GivenASourceProject $sourceProjectKey -WithRepo $repoName
    GivenATargetProject $targetProjectKey -WithNoRepo $repoName
    WhenMovingRepositoryBetweenProjects -SourceProjectKey $sourceProjectKey -TargetProjectKey $targetProjectKey -Repo $repoName
    ThenErrors -ShouldNotBeThrown
    ThenRepositoryShouldHaveMoved
}

Describe 'Move-BBServerRepository.when repository with same name already exists in target project' {
    Init
    GivenASourceProject $sourceProjectKey -WithRepo $repoName
    GivenATargetProject $targetProjectKey -WithRepo $repoName
    WhenMovingRepositoryBetweenProjects -SourceProjectKey $sourceProjectKey -TargetProjectKey $targetProjectKey -Repo $repoName
    ThenErrors -ShouldBeThrown 'This repository URL is already taken'
    ThenRepositoryShouldNotHaveMoved
}

Describe 'Move-BBServerRepository.when specified source project does not exist' {
    Init
    GivenATargetProject $targetProjectKey -WithRepo $repoName
    WhenMovingRepositoryBetweenProjects -SourceProjectKey 'Non-existent Project' -TargetProjectKey $targetProjectKey -Repo $repoName
    ThenErrors -ShouldBeThrown 'A project with key/ID ''Non-existent Project'' does not exist. Specified repository cannot be moved.'
}

Describe 'Move-BBServerRepository.when specified target project does not exist' {
    Init
    GivenASourceProject $sourceProjectKey -WithRepo $repoName
    WhenMovingRepositoryBetweenProjects -SourceProjectKey $sourceProjectKey -TargetProjectKey 'Non-existent Project' -Repo $repoName
    ThenErrors -ShouldBeThrown 'A project with key/ID ''Non-existent Project'' does not exist. Specified repository cannot be moved.'
    ThenRepositoryShouldNotHaveMoved
}

Describe 'Move-BBServerRepository.when specified repository does not exist' {
    Init
    GivenASourceProject $sourceProjectKey -WithRepo $repoName
    GivenATargetProject $targetProjectKey -WithRepo $repoName
    WhenMovingRepositoryBetweenProjects -SourceProjectKey $sourceProjectKey -TargetProjectKey $targetProjectKey -Repo 'Non-existent Repo'
    ThenErrors -ShouldBeThrown ('A repository with name ''Non-existent Repo'' does not exist in the project ''{0}''. Specified respository cannot be moved.' -f $sourceProjectKey)
}
