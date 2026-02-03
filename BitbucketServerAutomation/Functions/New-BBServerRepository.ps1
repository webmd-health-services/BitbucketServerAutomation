
function New-BBServerRepository
{
    <#
    .SYNOPSIS
    Creates a new repository in Bitbucket Server.

    .DESCRIPTION
    The `New-BBServerRepository` function creates a new Git repository in Bitbucket Server. It requires an project to
    exist where the repository should exist (all repositories in Bitbucket Server are part of a project).

    By default, the repository is setup to allow forking and be private. To disable forking, use the `NotForkable`
    switch. To make the repository public, use the `Public` switch.

    Use the `New-BBServerSession` function to generate the Session object that should get passed to the
    `Session` parameter.

    .EXAMPLE
    New-BBServerRepository -Session $session -ProjectKey 'BBSA' -Name 'fubarsnafu'

    Demonstrates how to create a repository.

    .EXAMPLE
    New-BBServerRepository -Session $session -ProjectKey 'BBSA' -Name 'fubarsnafu' -NotForkable -Public

    Demonstrates how to create a repository with different default settings. The repository will be not be forkable and
    will be public, not private.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The name of the repository to create.
        [Parameter(Mandatory)]
        [ValidateLength(1,128)]
        [String] $Name,

        # Disable the ability to fork the repository. The default is to allow forking.
        [switch] $NotForkable,

        # Make the repository public. Not sure what that means.
        [switch] $Public
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $forkable = $true
    if( $NotForkable )
    {
        $forkable = $false
    }

    $newRepoInfo = @{
                        name = $Name;
                        scmId = 'git';
                        forkable = $forkable;
                        public = [bool]$Public;
                    }

    $repo = $newRepoInfo | Invoke-BBServerRestMethod -Session $Session -Method Post -ApiName 'api' -ResourcePath ('projects/{0}/repos' -f $ProjectKey)
    if( $repo )
    {
        $repo | Add-PSTypeName -RepositoryInfo
    }
}