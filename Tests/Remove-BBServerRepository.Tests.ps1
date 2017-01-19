
Set-StrictMode -Version 'Latest'
#Requires -Version 4

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$conn = New-WhsBBServerConnection
$projectKey = Get-WhsBBServerTestProjectKey

if( $conn.Credential.UserName -eq 'svc-prod-lcsbitbucke' -or $conn.Uri -eq 'https://stash.portal.webmd.com/' -or $projectKey -eq 'WHS' )
{
    Write-Warning -Message ('These tests are being skipped so as not to inadvertently delete repositories from the main Bitbucket Server instance. Once we have a test instance and/or test project for improved isolation, we can re-enable these tests.')
    return
}

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

Remove-BBServerTestRepository -Connection $conn -ProjectKey $projectKey
