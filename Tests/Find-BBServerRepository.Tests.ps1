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

function ThenTheRepositoryShouldBeLike 
{
    param(
        [string]
        $Name
    )
    write-host $script:reposFound
    it ('should return a repo with name like ''{0}''' -f $Name) {
        $script:reposFound.name | Where-Object { $_ -match $Name } | Should -not -BeNullOrEmpty
    }
}
function ThenItShouldReturnMultipleRepositories
{
    it 'should return multiple repos' {
        ($script:reposFound | Measure-Object).Count | Should BeGreaterThan 1
    }
}

function ThenItShouldThrowAnError
{
    param(
        [string]
        $ExpectedError
    )
    it 'should throw an error' {
        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -not -BeNullOrEmpty
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
    ThenTheRepositoryShouldBeLike -name 'second'
}

Describe 'Find-BBServerRepository.When searching for a repository that matches a multiple repositories' {
    GivenARepository -Name 'first'
    GivenARepository -Name 'first-repo'
    WhenARepositoryIsRequested -RequestedRepo 'first*'
    ThenItShouldReturnMultipleRepositories
    ThenTheRepositoryShouldBeLike -name 'first*'
}