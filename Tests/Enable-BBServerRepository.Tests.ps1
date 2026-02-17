
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

    $script:session = New-BBServerTestSession
    $script:projectName = 'Disable-BBServerRepository'
    $script:project = New-BBServerProject -Session $script:session -Name $script:projectName -Key 'EBBR'

    function GivenArchivedRepository
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named
        )

        New-BBServerRepository -Session $script:session -ProjectKey $script:project.key -Name $Named
        Disable-BBServerRepository -Session $script:session -ProjectKey $script:project.key -RepoName $Named
    }

    function ThenRepository
    {
        param(
            [String] $Named,

            [switch] $Not,

            [switch] $IsArchived
        )

        if ($IsArchived)
        {
            $repo = Get-BBServerRepository -Session $script:session -ProjectKey $script:project.key -Name $Named
            $repo | Should -Not -BeNullOrEmpty
            if ($Not)
            {
                $repo.archived | Should -BeFalse
            }
            else
            {
                $repo.archived | Should -BeTrue
            }
        }
    }

    function WhenEnabling
    {
        param(
            [hashtable] $WithArgs = @{}
        )

        if (-not $WithArgs.ContainsKey('ProjectKey'))
        {
            $WithArgs['ProjectKey'] = $script:project.key
        }

        Enable-BBServerRepository -Session $script:session @WithArgs
    }
}

AfterAll {
    Remove-BBServerTestProject -Session $script:session -Key 'EBBR' -Force
}

Describe 'Enable-BBServerRepository' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'unarchives a repository' {
        GivenArchivedRepository 'EBBR001'
        WhenEnabling -WithArgs @{ RepoName = 'EBBR001' }
        ThenRepository 'EBBR001' -Not -IsArchived
    }

    It 'validates repository exists' {
        WhenEnabling -WithArgs @{ RepoName = 'EBBR002' ; ErrorAction = 'SilentlyContinue' }
        $Global:Error | Should -Match 'does not exist'
    }

    It 'does not re-unarchive a repository' {
        GivenArchivedRepository 'EBBR003'
        WhenEnabling -WithArgs @{ RepoName = 'EBBR003' }
        ThenRepository 'EBBR003' -Not -IsArchived
        Mock -CommandName 'Invoke-BBServerRestMethod' `
             -ModuleName 'BitbucketServerAutomation' `
             -ParameterFilter { $Method -eq 'PUT' }
        WhenEnabling -WithArgs @{ RepoName = 'EBBR003' }
        Should -Not -Invoke 'Invoke-BBServerRestMethod' -ModuleName 'BitbucketServerAutomation'
        ThenRepository 'EBBR003' -Not -IsArchived
    }

    It 'supports should process' {
        GivenArchivedRepository 'EBBR004'
        WhenEnabling -WithArgs @{ RepoName = 'EBBR004' ; WhatIf = $true }
        ThenRepository 'EBBR004' -IsArchived
    }

    It 'escapes URL paths' {
        WhenEnabling -WithArgs @{ ProjectKey = 'fu\bar' ; RepoName = 'sna\fu' ; ErrorAction = 'SilentlyContinue' }
        $Global:Error | Should -Not -BeNullOrEmpty
    }
}
