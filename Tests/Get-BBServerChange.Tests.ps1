
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

    $script:projectKey = 'GBBSCHANGE'
    $script:session = New-BBServerTestSession -ProjectKey $script:projectKey -ProjectName 'Get-BBServerChange Tests'
    $script:repo = $null
    $script:repoRoot = $null
    $script:repoName = $null
    $script:commitHash = $null

    function GivenARepositoryWithBranches
    {
        [CmdletBinding()]
        param(
            $BranchName
        )

        Push-Location -Path $script:repoRoot
        try
        {
            New-Item -Path 'file' -ItemType File
            Add-GitItem -Path 'file'
            Save-GitCommit -Message 'Initializing repository for `Get-BBServerChange` tests'
            Send-GitCommit -Credential $script:session.Credential

            New-GitBranch -Name $BranchName
            Update-GitRepository -Revision $BranchName

            New-Item -Path 'test.txt' -ItemType 'File' -Force
            Add-GitItem -Path 'test.txt'
            $script:commitHash =
                Save-GitCommit -Message 'adding file to create a change' | Select-Object -ExpandProperty 'Sha'
            Send-GitCommit -Credential $script:session.Credential
        }
        finally
        {
            Pop-Location
        }
    }

    function GivenANewBranch
    {
        param(
            [String] $branchName,
            [String] $start
        )

        New-BBServerBranch -Session $script:session `
                           -ProjectKey $script:projectKey `
                           -RepoName $script:repoName `
                           -BranchName $branchName `
                           -StartPoint $start

    }

    function GivenANewTag
    {
        param(
            [String] $name
        )

        New-BBServerTag -Session $script:session `
                        -ProjectKey $script:projectKey `
                        -RepositoryKey $script:repoName `
                        -Name $name `
                        -CommitID $script:commitHash
    }

    function WhenGettingChanges
    {
        [CmdletBinding()]
        param(
            [String] $To,

            [String] $from
        )

        $script:changesList = Get-BBServerChange -Session $script:session `
                                                 -ProjectKey $script:projectKey `
                                                 -RepoName $script:repoName `
                                                 -From $from `
                                                 -To $To
    }

    function ThenWeShouldGetNoChanges
    {
        $script:changesList | should -BeNullOrEmpty
    }

    function ThenWeShouldGetChanges
    {
        param(
            [String] $ExpectedChanges
        )

        $script:changesList.path | Where-Object {$_ -match $ExpectedChanges } | Should -Not -BeNullOrEmpty
    }

    function ThenItShouldThrowAnError
    {
        param(
            [String] $ExpectedError
        )

        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-BBServerChange' {
    BeforeEach {
        $script:repo = New-BBServerTestRepository -Session $script:session -ProjectKey $script:projectKey
        $script:repoRoot = $script:repo | Initialize-TestRepository -Session $script:session
        $script:repoName = $script:repo | Select-Object -ExpandProperty 'name'

        # $DebugPreference = 'Continue'
        Write-Debug -Message ('Project: {0}' -f $script:projectKey)
        Write-Debug -message ('Repository: {0}' -f $script:repoName)

        $Global:Error.Clear()
    }

    It 'checks for changes on a branch that does not exist' {
        GivenARepositoryWithBranches -branchName 'branchA'
        WhenGettingChanges -From 'branchA' -To 'branchIDontExist' -ErrorAction SilentlyContinue
        ThenItShouldThrowAnError -ExpectedError 'does not exist in repository'
        ThenWeShouldGetNoChanges
    }

    It 'checks for changes on two branches we should get changes' {
        GivenARepositoryWithBranches -branchName 'branchA'
        GivenANewBranch -branchName 'branchB' -start 'master'
        WhenGettingChanges -From 'branchA' -To 'branchB'
        ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
    }

    It 'checks for changes on a commit we should get changes' {
        GivenARepositoryWithBranches -branchName 'branchA'
        GivenANewBranch -branchName 'branchB' -start 'master'
        WhenGettingChanges -From $script:commitHash -To 'branchB'
        ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
    }

    It 'checks for changes on a tag we should get changes' {
        GivenARepositoryWithBranches -branchName 'branchA'
        GivenANewBranch -branchName 'branchB' -start 'master'
        GivenANewTag -Name 'testTag'
        WhenGettingChanges -From 'testTag' -To 'branchB'
        ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
    }

    It 'checks for changes on a tag with a name that needs encoding we should get changes' {
        GivenARepositoryWithBranches -branchName 'branchA'
        GivenANewBranch -branchName 'branchB' -start 'master'
        GivenANewTag -Name 'feature/test+tag.please&Encode'
        WhenGettingChanges -From 'feature/test+tag.please&Encode' -To 'branchB'
        ThenWeShouldGetChanges -ExpectedChanges 'test.txt'
    }

    It 'checks for changes on a tag with a name that has invalid characters we should not get changes' {
        GivenARepositoryWithBranches -branchName 'branchA'
        GivenANewBranch -branchName 'branchB' -start 'master'
        WhenGettingChanges -From 'feature/test+tag?please&Encode' -To 'branchB' -ErrorAction SilentlyContinue
        ThenItShouldThrowAnError -ExpectedError 'does not exist in repository'
        ThenWeShouldGetNoChanges
    }

    It 'checks for changes on two branches that are up to date we should get No changes' {
        GivenARepositoryWithBranches -branchName 'branchA'
        GivenANewBranch -branchName 'branchB' -start 'master'
        WhenGettingChanges -From 'branchB' -To 'master'
        ThenWeShouldGetNoChanges
    }
}