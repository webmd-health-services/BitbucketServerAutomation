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

$projectKey = 'NBBSREPO'
$conn = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerRepository Tests'

Describe 'New-BBServerRepository when the new repository doesn''t exist' {
    $repoName = New-TestRepoName
    $repo = New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName

    It 'should return the new repository' {
        $repo | Should Not BeNullOrEmpty
    }

    It 'should be typed' {
        $repo.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo' | Should Be $true
    }

    It 'should be forkable' {
        $repo.forkable | Should Be $true
    }
    
    It 'should not be public' {
        $repo.public | Should Be $false
    }

    It 'should create the repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName | Should Not BeNullOrEmpty
    }
}

Describe 'New-BBServerRepository when the repository already exists' {
    $Global:Error.Clear()
    $repoName = New-TestRepoName
    $repo = New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName
    $repo = New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName -ErrorAction SilentlyContinue
    It 'should return nothing' {
        $repo | Should BeNullOrEmpty
    }
    It 'should write an error' {
        $Global:Error | Should Match 'already taken'
    }
}

Describe 'New-BBServerRepository when creating a repository with custom settings' {
    $repoName = New-TestRepoName
    $repo = New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName -NotForkable -Public
    It 'should not be forkable' {
        $repo.forkable | Should Be $false
    }    
    It 'should be public' {
        $repo.public | Should Be $true
    }    
}
