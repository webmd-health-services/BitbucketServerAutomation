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

$conn = New-BBServerTestConnection
$projectKey = 'NBBSPROJ'

function New-TestProjectInfo
{
    $key = ([IO.Path]::GetRandomFileName()) -replace '[^A-Za-z0-9_]','_'
    $key -replace '^\d+',''
    'New-BBServerProject New Project {0}' -f [IO.Path]::GetRandomFileName()
}

Describe 'New-BBServerProject.when project doesn''t exist' {
    $key,$name = New-TestProjectInfo
    $description = 'description'

    $project = New-BBServerProject -Connection $conn -Key $key -Name $name -Description $description

    It 'should return the project' {
        $project | Should Not BeNullOrEmpty
        $project.Key | Should Be $key
        $project.Name | Should Be $name
        $project.Description | Should Be $description
    }

    It 'should create the project' {
        $project2 = Get-BBServerProject -Connection $conn -Name $name 
        $project2 | Should Not BeNullOrEmpty
        $project2.id | Should Be $project.id
    }

    It 'should add type info' {
        $project.pstypenames -contains 'Atlassian.Bitbucket.Server.ProjectInfo' | Should Be $true
    }
}

Describe 'New-BBServerProject.when project exists' {
    $key,$name = New-TestProjectInfo

    $project = New-BBServerProject -Connection $conn -Key $key -Name $name

    $Global:Error.Clear()

    $project2 = New-BBServerProject -Connection $conn -Key $key -Name $name -ErrorAction SilentlyContinue

    It 'should fail' {
        $Global:Error | Should Not BeNullOrEmpty
        $Global:Error | Should Match 'The project (key|name) is already in use'
    }

    It 'should not return anything' {
        $project2 | Should BeNullOrEmpty
    }
}

Describe 'New-BBServerProject.when description not provided' {
    $key,$name = New-TestProjectInfo

    $project = New-BBServerProject -Connection $conn -Key $key -Name $name -ErrorVariable 'errors'

    It 'should not write any errors' {
        $errors | Should BeNullOrEmpty
    }

    It 'should be created with no description' {
        $project.Description | Should BeNullOrEmpty
    }
}
