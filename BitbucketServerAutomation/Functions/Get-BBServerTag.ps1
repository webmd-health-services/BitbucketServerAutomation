
function Get-BBServerTag
{
    <#
    .SYNOPSIS
    Gets tags from a repository in Bitbucket Server.

    .DESCRIPTION
    The `Get-BBServerTag` function returns the git tags associated with a particular repository in Bitbucket Server. It
    will one or more of the most recent git tags in a repo, up to a max of 25, after which it will truncate the least
    recent tags in favor of the most recent tags. If the repo has zero tags an error will be thrown.

    The tags are obtained through a rest call, and the return from that call is a collection of JSON objects with the
    related Tag information. This is returned from `Get-BBServerTag` in the form of a list of PowerShell Objects.

    .EXAMPLE
    Get-BBServerTag -Session $session -ProjectKey $key -RepositoryKey $repoName

    Demonstrates how to obtain the git tags associated with a particular repository
    #>
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key of the repository's project.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The key of the repository.
        [Parameter(Mandatory)]
        [String] $RepositoryKey

    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-BBServerRestMethod -Session $Session -Method Get -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $ProjectKey, $RepositoryKey) -IsPaged
}


