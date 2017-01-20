
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$conn = New-WhsBBServerConnection
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
