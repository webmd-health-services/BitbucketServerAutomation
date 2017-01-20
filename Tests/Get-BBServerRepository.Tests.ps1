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

$projectKey = 'GBBSREPO'
$conn = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerRepository Tests'

for( $idx = 0; $idx -lt 30; ++$idx )
{
    New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $idx -ErrorAction Ignore | Out-Null
}

Describe 'Get-BBServerRepository when getting all repositories for a project' {
    [object[]]$repos = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey 
    It 'should get all the repositories' {
        $repos.Count | Should BeGreaterThan 25
    }
    It 'should add type info' {
        $repos | ForEach-Object { ($_.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo') | Should Be $true } 
    }

}

Describe 'Get-BBServerRepository when getting a specific repository' {
    $repo = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name '1'
    It 'should get it' {
        $repo | Should Not BeNullOrEmpty
        $repo.name | Should Be '1'
    }
    It 'should add type info' {
        $repo.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo' | Should Be $true
    }
}

Describe 'Get-BBServerRepository when getting a specific repository with a wildcard' {
    $errors = @()
    [object[]]$repo = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name '1*' -ErrorVariable 'errors'
    It 'should get multiple repositories' {
        $errors | Should BeNullOrEmpty
        $repo.Count | Should BeGreaterThan 1
        $repo | Select-Object -ExpandProperty 'name' | Should Match '^1'
    }
}

Describe 'Get-BBServerRepository when getting a repository that does not exist' {
    $Global:Error.Clear()
    $repo = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name 'fubarsnafu' -ErrorAction SilentlyContinue
    It 'should not return anything' {
        $repo | Should BeNullOrEmpty
    }

    It 'should write an error' {
        $Global:Error | Should Match 'does not exist'
    }
}
