
function Remove-BBServerTag
{
    <#
    .SYNOPSIS
    Removes specified tags from a repository in Bitbucket Server.

    .DESCRIPTION
    The `Remove-BBServerTag` function takes an array of git tags and removes them from the specified Bitbucket Server repository. If any of the requested tags do not exist on the server, an error is thrown.

    .EXAMPLE
    Remove-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName -TagName $tag.displayId

    Demonstrates how to remove the git tag for the associated repo
    #>
    param(
        [Parameter(Mandatory=$true)]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        [object]$Connection,

        [Parameter(Mandatory=$true)]
        # The key of the repository's project.
        [String]$ProjectKey,

        [Parameter(Mandatory=$true)]
        # The key of the repository.
        [String]$RepositoryKey,

        [Parameter(Mandatory=$true)]
        # The name of the tag to be deleted.
        [String[]]$TagName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    foreach( $tag in $TagName )
    {
        Invoke-BBServerRestMethod -Connection $Connection -Method DELETE -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags/{2}' -f $ProjectKey, $RepositoryKey, $tag)
    }
}


