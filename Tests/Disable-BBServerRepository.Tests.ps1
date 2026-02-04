
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

    $script:session = New-BBServerTestSession
    $script:projectName = 'Disable-BBServerRepository'
    $script:project = New-BBServerProject -Session $script:session -Name $script:projectName -Key 'DBBR'

    function GivenRepository
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named
        )

        New-BBServerRepository -Session $script:session -ProjectKey $script:project.key -Name $Named
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

    function WhenDisabling
    {
        param(
            [hashtable] $WithArgs = @{}
        )

        if (-not $WithArgs.ContainsKey('ProjectKey'))
        {
            $WithArgs['ProjectKey'] = $script:project.key
        }

        Disable-BBServerRepository -Session $script:session @WithArgs
    }
}

AfterAll {
    Remove-BBServerTestProject -Session $script:session -Key 'DBBR' -Force
}

Describe 'Disable-BBServerRepository' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'archives a repository' {
        GivenRepository 'DBBR001'
        WhenDisabling -WithArgs @{ RepoName = 'DBBR001' }
        ThenRepository 'DBBR001' -IsArchived
    }

    It 'validates repository exists' {
        WhenDisabling -WithArgs @{ RepoName = 'DBBR002' ; ErrorAction = 'SilentlyContinue' }
        $Global:Error | Should -Match 'does not exist'
    }

    It 'does not re-archive a repository' {
        GivenRepository 'DBBR003'
        WhenDisabling -WithArgs @{ RepoName = 'DBBR003' }
        ThenRepository 'DBBR003' -IsArchived
        Mock -CommandName 'Invoke-BBServerRestMethod' `
             -ModuleName 'BitbucketServerAutomation' `
             -ParameterFilter { $Method -eq 'PUT' }
        WhenDisabling -WithArgs @{ RepoName = 'DBBR003' }
        Should -Not -Invoke 'Invoke-BBServerRestMethod' -ModuleName 'BitbucketServerAutomation'
        ThenRepository 'DBBR003' -IsArchived
    }

    It 'supports should process' {
        GivenRepository 'DBBR004'
        WhenDisabling -WithArgs @{ RepoName = 'DBBR004' ; WhatIf = $true }
        ThenRepository 'DBBR004' -Not -IsArchived
    }

    It 'escapes URL paths' {
        WhenDisabling -WithArgs @{ ProjectKey = 'fu\bar' ; RepoName = 'sna\fu' ; ErrorAction = 'SilentlyContinue' }
        $Global:Error | Should -Not -BeNullOrEmpty
    }
}
