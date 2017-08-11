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

$reposFound = $null
$projectKey = 'GBBSREPO'
$connection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Find-BBServerRepository Tests'
function GivenARepository
{
    param(
        [String]
        $Name
    )
    $GetRepo = Get-BBServerRepository -Connection $connection -ProjectKey $projectKey -Name $Name

    if ( $GetRepo )
    {
        Remove-BBServerRepository -Connection $connection -ProjectKey $ProjectKey -Name $Name -Force
    }
    New-BBServerRepository -Connection $connection -ProjectKey $ProjectKey -Name $Name | Out-Null
}
function WhenARepositoryIsRequested
{
    param(
        [String]
        $RequestedRepo
    )
    $Script:reposFound = Find-BBServerRepository -Connection $connection -Name $RequestedRepo
}

function ThenNoRepositoryShouldBeReturned 
{
    it 'should not return any repos' {
        ($script:reposFound | Measure-Object).Count | Should -be 0
    }
}

function ThenRepositoryReturned 
{
    param(
        [string[]]
        $Names
    )
    $Names | ForEach-Object {
        it ('should return a repo with names ''{0}''' -f $_) {
            $currName = $_
            $script:reposFound.name | Where-Object { $_ -match $currName} | Should -not -BeNullOrEmpty
        }
    }
    it 'should return the same number of repositories' {
        ($script:reposFound | Measure-Object).Count | Should -match ($Names | Measure-Object).count
    }
}

Describe 'Find-BBServerRepository.When searching for a repository that doesn''t exist' {
    GivenARepository -Name 'first'
    WhenARepositoryIsRequested -RequestedRepo 'badRepo'
    ThenNoRepositoryShouldBeReturned
}

Describe 'Find-BBServerRepository.When searching for a repository that matches a single repository' {
    GivenARepository -Name 'first'
    GivenARepository -Name 'second'
    WhenARepositoryIsRequested -RequestedRepo 'second'
    ThenRepositoryReturned -name 'second'
}

Describe 'Find-BBServerRepository.When searching for a repository that matches a multiple repositories' {
    GivenARepository -Name 'first'
    GivenARepository -Name 'first-repo'
    GivenARepository -Name 'doesntMatch'
    WhenARepositoryIsRequested -RequestedRepo 'first*'
    ThenRepositoryReturned -name 'first', 'first-repo'
}