
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

    $script:sourceProjectKey = 'SMOVEBBSR'
    $script:targetProjectKey = 'TMOVEBBSR'
    $script:repoName = $null
    $script:session = New-BBServerTestSession -ProjectKey $script:sourceProjectKey `
                                              -ProjectName 'Move-BBServerRepository Tests - Source'

    function GivenASourceProject
    {
        [CmdletBinding()]
        param(
            [string]
            $ProjectKey,

            [string]
            $WithRepo
        )

        $getRepo =
            Get-BBServerRepository -Session $script:session -ProjectKey $ProjectKey -Name $WithRepo -ErrorAction Ignore
        if ( !$getRepo )
        {
            New-BBServerRepository -Session $script:session -ProjectKey $ProjectKey -Name $WithRepo | Out-Null
        }
    }

    function GivenATargetProject
    {
        [CmdletBinding()]
        param(
            [string]
            $ProjectKey,

            [string]
            $WithNoRepo,

            [string]
            $WithRepo
        )

        if( $WithNoRepo )
        {
            $getRepo = Get-BBServerRepository -Session $script:session `
                                              -ProjectKey $ProjectKey `
                                              -Name $WithNoRepo `
                                              -ErrorAction Ignore
            if ( $getRepo )
            {
                Remove-BBServerRepository -Session $script:session -ProjectKey $ProjectKey -Name $WithNoRepo -Force
            }
        }

        $getProject = Get-BBServerProject -Session $script:session `
                                          -Name 'Move-BBServerRepository Tests - Target' `
                                          -ErrorAction Ignore
        if ( !$getProject )
        {
            New-BBServerProject -Session $script:session -Key $ProjectKey -Name 'Move-BBServerRepository Tests - Target'
        }

        if( $WithRepo )
        {
            $getRepo = Get-BBServerRepository -Session $script:session `
                                              -ProjectKey $ProjectKey `
                                              -Name $WithRepo `
                                              -ErrorAction Ignore
            if ( !$getRepo )
            {
                New-BBServerRepository -Session $script:session -ProjectKey $ProjectKey -Name $WithRepo | Out-Null
            }
        }
    }

    function WhenMovingRepositoryBetweenProjects
    {
        [CmdletBinding()]
        param(
            [String] $SourceProjectKey,

            [String] $TargetProjectKey,

            [String] $Repo
        )

        $Global:Error.Clear()

        Move-BBServerRepository -Session $script:session `
                                -ProjectKey $SourceProjectKey `
                                -RepoName $Repo `
                                -TargetProjectKey $TargetProjectKey `
                                -ErrorAction SilentlyContinue
    }

    function ThenErrors
    {
        [CmdletBinding()]
        param(
            [switch] $ShouldNotBeThrown,

            [string] $ShouldBeThrown
        )

        if( $ShouldNotBeThrown )
        {
            $Global:Error | Should -BeNullOrEmpty
        }

        if( $ShouldBeThrown )
        {
            $Global:Error | Should -Match $ShouldBeThrown
        }
    }

    function ThenRepositoryShouldHaveMoved
    {
        [CmdletBinding()]
        param(
        )

        Get-BBServerRepository -Session $script:session -ProjectKey $script:targetProjectKey -Name $script:repoName |
            Should -Not -BeNullOrEmpty

        Get-BBServerRepository -Session $script:session `
                               -ProjectKey $script:sourceProjectKey `
                               -Name $script:repoName `
                               -ErrorAction Ignore |
            Should -BeNullOrEmpty
    }

    function ThenRepositoryShouldNotHaveMoved
    {
        [CmdletBinding()]
        param(
        )

        Get-BBServerRepository -Session $script:session `
                               -ProjectKey $script:sourceProjectKey `
                               -Name $script:repoName `
                               -ErrorAction Ignore |
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Move-BBServerRepository' {
    BeforeEach {
        $script:repoName =
            New-BBServerTestRepository -Session $script:session -ProjectKey $script:sourceProjectKey |
            Select-Object -ExpandProperty 'name'

        # $DebugPreference = 'Continue'
        Write-Debug -Message ('Project: {0}' -f $script:sourceProjectKey)
        Write-Debug -message ('Repository: {0}' -f $script:repoName)
    }

    It 'moves a repository between two projects' {
        GivenASourceProject $script:sourceProjectKey -WithRepo $script:repoName
        GivenATargetProject $script:targetProjectKey -WithNoRepo $script:repoName
        WhenMovingRepositoryBetweenProjects -SourceProjectKey $script:sourceProjectKey `
                                            -TargetProjectKey $script:targetProjectKey `
                                            -Repo $script:repoName
        ThenErrors -ShouldNotBeThrown
        ThenRepositoryShouldHaveMoved
    }

    It 'validates target repository does not exist' {
        GivenASourceProject $script:sourceProjectKey -WithRepo $script:repoName
        GivenATargetProject $script:targetProjectKey -WithRepo $script:repoName
        WhenMovingRepositoryBetweenProjects -SourceProjectKey $script:sourceProjectKey `
                                            -TargetProjectKey $script:targetProjectKey `
                                            -Repo $script:repoName
        ThenErrors -ShouldBeThrown 'This repository URL is already taken'
        ThenRepositoryShouldNotHaveMoved
    }

    It 'validates source project exists' {
        GivenATargetProject $script:targetProjectKey -WithRepo $script:repoName
        WhenMovingRepositoryBetweenProjects -SourceProjectKey 'Non-existent Project' `
                                            -TargetProjectKey $script:targetProjectKey `
                                            -Repo $script:repoName
        $expectedMsg = 'A project with key/ID ''Non-existent Project'' does not exist. Specified repository cannot ' +
                       'be moved.'
        ThenErrors -ShouldBeThrown $expectedMsg
    }

    It 'validates destination project exists' {
        GivenASourceProject $script:sourceProjectKey -WithRepo $script:repoName
        WhenMovingRepositoryBetweenProjects -SourceProjectKey $script:sourceProjectKey `
                                            -TargetProjectKey 'Non-existent Project' `
                                            -Repo $script:repoName
        $expectedMsg = 'A project with key/ID ''Non-existent Project'' does not exist. Specified repository cannot ' +
                       'be moved.'
        ThenErrors -ShouldBeThrown $expectedMsg
        ThenRepositoryShouldNotHaveMoved
    }

    It 'validates source repositry exists' {
        GivenASourceProject $script:sourceProjectKey -WithRepo $script:repoName
        GivenATargetProject $script:targetProjectKey -WithRepo $script:repoName
        WhenMovingRepositoryBetweenProjects -SourceProjectKey $script:sourceProjectKey `
                                            -TargetProjectKey $script:targetProjectKey `
                                            -Repo 'Non-existent Repo'
        $expectedMsg = 'A repository with name ''Non-existent Repo'' does not exist in the project ' +
                       "'${script:sourceProjectKey}'. Specified respository cannot be moved."
        ThenErrors -ShouldBeThrown $expectedMsg
    }
}
