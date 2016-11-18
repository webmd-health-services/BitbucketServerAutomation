
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$conn = New-WhsBBServerConnection
$projectKey = Get-WhsBBServerTestProjectKey

Describe 'Get-BBServerRepository when getting all repositories for a project' {
    [object[]]$repos = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey 
    It 'should get all the repositories' {
        $repos.Count | Should BeGreaterThan 25
    }
    It 'should add type info' {
        $repos | ForEach-Object { $_.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo' } | Should Be $true
    }
}

Describe 'Get-BBServerRepository when getting a specific repository' {
    $repo = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name 'BitbucketServerAutomation'
    It 'should get it' {
        $repo | Should Not BeNullOrEmpty
        $repo.name | Should Be 'BitbucketServerAutomation'
    }
    It 'should add type info' {
        $repo.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo' | Should Be $true
    }
}

Describe 'Get-BBServerRepository when getting a specific repository with a wildcard' {
    $errors = @()
    [object[]]$repo = Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name 'WebMD.*' -ErrorVariable 'errors'
    It 'should get multiple repositories' {
        $errors | Should BeNullOrEmpty
        $repo.Count | Should BeGreaterThan 1
        $repo | Select-Object -ExpandProperty 'name' | Should Match '^WebMD\.'
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
