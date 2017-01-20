
Set-StrictMode -Version 'Latest'
#Requires -Version 4

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
