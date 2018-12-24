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

$projectKey = 'RBBSREPO'
$conn = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Remove-BBServerRepository Tests'

$myConfirmPref = $ConfirmPreference
# If you want to see confirmation boxes, then comment out this line.
$Global:ConfirmPreference = 'None'

Describe 'Remove-BBServerRepository when the repository doesn''t exist' {
    $Global:Error.Clear()

    $repo = Remove-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name ([IO.Path]::GetRandomFileName())
    
    It 'should return nothing' {
        $repo | Should BeNullOrEmpty
    }

    It 'should not write an error' {
        $Global:Error | Should BeNullOrEmpty
    }
}

Describe 'Remove-BBServerRepository when the repository exists' {
    $repoName = New-TestRepoName
    New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName
    $repo = Remove-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName

    It 'should return nothing' {
        $repo | Should BeNullOrEmpty
    }

    It 'should delete the repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }
}

Describe 'Remove-BBServerRepository when using WhatIf' {
    $repoName = New-TestRepoName
    New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName
    $repo = Remove-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName -WhatIf

    It 'should return nothing' {
        $repo | Should BeNullOrEmpty
    }

    It 'should not delete the repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName | Should Not BeNullOrEmpty
    }
}

Describe 'Remove-BBServerRepository when piping repository info objects' {
    $repo1Name = New-TestRepoName
    $repo1 = New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo1Name
    $repo2Name = New-TestRepoName
    $repo2 = New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo2Name

    $repo1,$repo2 | Remove-BBServerRepository -Connection $conn

    It 'should delete the first repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo1Name -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }

    It 'should delete the second repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo2Name -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }
}

Describe 'Remove-BBServerRepository when piping repository names' {
    $repo1Name = New-TestRepoName
    New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo1Name
    $repo2Name = New-TestRepoName
    New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo2Name

    $repo1Name,$repo2Name | Remove-BBServerRepository -Connection $conn -ProjectKey $projectKey

    It 'should delete the first repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo1Name -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }

    It 'should delete the second repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repo2Name -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }
}

Describe 'Remove-BBServerRepository when using a name but project key missing' {
    $Global:Error.Clear()

    $repoName = New-TestRepoName
    New-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName

    Remove-BBServerRepository -Connection $conn -Name $repoName -ErrorAction SilentlyContinue

    It 'should write an error' {
        $Global:Error | Should Match 'parameter missing'
    }

    It 'should not delete repository' {
        Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name $repoName | Should Not BeNullOrEmpty
    }
}

$Global:ConfirmPreference = $myConfirmPref