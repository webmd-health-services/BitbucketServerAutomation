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

$projectKey = 'RENAMEBBSR'
$sourceRepoName = 'Source-RenameRepo'
$targetRepoName = 'Target-RenameRepo'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Rename-BBServerRepository Tests'

function GivenAProjectWithRepositories
{
    [CmdletBinding()]
    param(
        [string[]]
        $RepoNames
    )

    $getRepos = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey
    if( $getRepos )
    {
        $getRepos | Where-Object { $RepoNames -notcontains $_.name } |
            Remove-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Force

        $RepoNames = $RepoNames | Where-Object { $getRepos.name -notcontains $_ }        
    }

    if( $RepoNames )
    {
        $RepoNames | ForEach-Object { New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $_ }
    }
}

function WhenRenamingARepository
{
    [CmdletBinding()]
    param(
        [string]
        $SourceRepo,

        [string]
        $To
    )

    $Global:Error.Clear()

    $renameBBServerRepo = Rename-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -RepoName $SourceRepo -TargetRepoName $To -ErrorAction SilentlyContinue
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

function ThenRepositoryShouldBeRenamed
{
    [CmdletBinding()]
    param(
    )

    It 'the specified repository should exist with the new target name' {
        Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $targetRepoName | Should Not BeNullOrEmpty
    }

    It 'the specified repository should no longer exist with the original name' {
        Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $sourceRepoName -ErrorAction Ignore | Should BeNullOrEmpty
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

Describe 'Rename-BBServerRepository.when renaming a repository' {
    GivenAProjectWithRepositories $sourceRepoName
    WhenRenamingARepository $sourceRepoName -To $targetRepoName
    ThenErrors -ShouldNotBeThrown
    ThenRepositoryShouldBeRenamed
}

Describe 'Rename-BBServerRepository.when a repository with the requested target name already exists' {
    GivenAProjectWithRepositories $sourceRepoName, $targetRepoName
    WhenRenamingARepository $sourceRepoName -To $targetRepoName
    ThenErrors -ShouldBeThrown ('A repository with name ''{0}'' already exists in the project ''{1}''. Specified respository cannot be renamed.' -f $targetRepoName, $projectKey)
}

Describe 'Rename-BBServerRepository.when the specified repository does not exist' {
    GivenAProjectWithRepositories
    WhenRenamingARepository $sourceRepoName -To $targetRepoName
    ThenErrors -ShouldBeThrown ('A repository with name ''{0}'' does not exist in the project ''{1}''. Specified respository cannot be renamed.' -f $sourceRepoName, $projectKey)
}
