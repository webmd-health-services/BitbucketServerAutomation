
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

    $script:projectKey = 'NBBSBRANCH'
    $script:repo = $null
    $script:repoRoot = $null
    $script:repoName = $null
    $script:session = New-BBServerTestSession -ProjectKey $script:projectKey -ProjectName 'New-BBServerBranch Tests'

    function GivenARepository
    {
        param(
            $WithBranch
        )

        New-TestRepoCommit -RepoRoot $script:repoRoot -Session $script:session

        if ($WithBranch)
        {
            New-GitBranch -Name $WithBranch -RepoRoot $script:repoRoot
            Update-GitRepository -Revision $WithBranch -RepoRoot $script:repoRoot
            Send-GitCommit -SetUpstream -RepoRoot $script:repoRoot -Credential $script:session.Credential
        }
    }

    function WhenCreatingANewBranch
    {
        [CmdletBinding()]
        param(
            [string]
            $BranchName,

            [string]
            $StartPoint,

            [switch]
            $ShouldThrowInvalidBranchPointException,

            [switch]
            $ShouldThrowDuplicateBranchException
        )

        $Global:Error.Clear()

        New-BBServerBranch -Session $script:session `
                           -ProjectKey $script:projectKey `
                           -RepoName $script:repoName `
                           -BranchName $BranchName `
                           -StartPoint $StartPoint `
                           -ErrorAction SilentlyContinue |
            Out-Null

        if( $ShouldThrowInvalidBranchPointException )
        {
            $Global:Error | Should -Match "Branch point '${StartPoint}' does not exist"
        }
        elseif( $ShouldThrowDuplicateBranchException )
        {
            $Global:Error | Should -Match ('A branch with the name ''{0}'' already exists' -f $BranchName)
        }
        else
        {
            $Global:Error | Should -BeNullOrEmpty
        }
    }

    function ThenNewBranch
    {
        [CmdletBinding()]
        param(
            [String] $ShouldBeCreated,

            [String] $ShouldNotBeCreated,

            [String] $ShouldNotBeCreatedAndOnlyExistOnce
        )

        if( $ShouldBeCreated )
        {
            $checkBranch = Get-BBServerBranch -Session $script:session `
                                              -ProjectKey $script:projectKey `
                                              -RepoName $script:repoName `
                                              -BranchName $ShouldBeCreated

            $checkBranch.displayId -eq $ShouldBeCreated | Should -BeTrue
        }

        if( $ShouldNotBeCreated )
        {
            $checkBranch = Get-BBServerBranch -Session $script:session `
                                              -ProjectKey $script:projectKey `
                                              -RepoName $script:repoName `
                                              -BranchName $ShouldNotBeCreated

            $checkBranch | Should -BeNullOrEmpty
        }

        if( $ShouldNotBeCreatedAndOnlyExistOnce )
        {
            [array]$checkBranch = Get-BBServerBranch -Session $script:session `
                                                     -ProjectKey $script:projectKey `
                                                     -RepoName $script:repoName `
                                                     -BranchName $ShouldNotBeCreatedAndOnlyExistOnce

            $checkBranch.Count | Should -Be 1
        }
    }
}

Describe 'New-BBServerBranch' {
    BeforeEach {
        $script:repo = New-BBServerTestRepository -Session $script:session -ProjectKey $script:projectKey
        $script:repoRoot = $script:repo | Initialize-TestRepository -Session $script:session
        $script:repoName = $script:repo | Select-Object -ExpandProperty 'name'

        # $DebugPreference = 'Continue'
        Write-Debug -Message ('Project: {0}' -f $script:projectKey)
        Write-Debug -message ('Repository: {0}' -f $script:repoName)
    }

    It 'create a new branch based on an existing master branch' {
        GivenARepository
        WhenCreatingANewBranch -BranchName 'branch_cloned_from_master' -StartPoint 'master'
        ThenNewBranch -ShouldBeCreated 'branch_cloned_from_master'
    }

    It 'creates a new branch based on an existing Commit ID' {
        GivenARepository
        $getBranch = Get-BBServerBranch -Session $script:session `
                                        -ProjectKey $script:projectKey `
                                        -RepoName $script:repoName `
                                        -BranchName 'master'
        $newBranchName = ('branch_cloned_from_commitid_{0}' -f $getBranch.latestCommit)
        WhenCreatingANewBranch -BranchName $newBranchName -StartPoint $getBranch.latestCommit
        ThenNewBranch -ShouldBeCreated $newBranchName
    }

    It 'does not create branch from an invalid StartPoint' {
        GivenARepository
        WhenCreatingANewBranch -BranchName 'branch_cloned_from_invalid_start' `
                               -StartPoint 'InvalidStartPoint' `
                               -ShouldThrowInvalidBranchPointException
        ThenNewBranch -ShouldNotBeCreated 'branch_cloned_from_invalid_start'
    }

    It 'handles existing branch' {
        GivenARepository -WithBranch 'branch_cloned_from_master'
        WhenCreatingANewBranch -BranchName 'branch_cloned_from_master' `
                               -StartPoint 'master' `
                               -ShouldThrowDuplicateBranchException
        ThenNewBranch -ShouldNotBeCreatedAndOnlyExistOnce 'branch_cloned_from_master'
    }
}