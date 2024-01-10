
function Get-BBServerTag
{
    <#
    .SYNOPSIS
    Gets tags from a repository in Bitbucket Server.

    .DESCRIPTION
    The `Get-BBServerTag` function returns the git tags associated with a particular repository in Bitbucket Server. It will one or more of the most recent git tags in a repo, up to a max of 25, after which it will truncate the least recent tags in favor of the most recent tags. If the repo has zero tags an error will be thrown.

    The tags are obtained through a rest call, and the return from that call is a collection of JSON objects with the related Tag information. This is returned from `Get-BBServerTag` in the form of a list of PowerShell Objects.

    .EXAMPLE
    Get-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName

    Demonstrates how to obtain the git tags associated with a particular repository
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository's project.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository.
        $RepositoryKey

    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $ProjectKey, $RepositoryKey) -IsPaged
}


