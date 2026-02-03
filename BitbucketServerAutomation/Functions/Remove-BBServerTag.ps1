
function Remove-BBServerTag
{
    <#
    .SYNOPSIS
    Removes specified tags from a repository in Bitbucket Server.

    .DESCRIPTION
    The `Remove-BBServerTag` function takes an array of git tags and removes them from the specified Bitbucket Server
    repository. If any of the requested tags do not exist on the server, an error is thrown.

    .EXAMPLE
    Remove-BBServerTag -Session $session -ProjectKey $key -RepositoryKey $repoName -TagName $tag.displayId

    Demonstrates how to remove the git tag for the associated repo
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
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
        [String] $RepositoryKey,

        # The name of the tag to be deleted.
        [Parameter(Mandatory)]
        [String[]] $TagName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    foreach( $tag in $TagName )
    {
        Invoke-BBServerRestMethod -Session $Session -Method DELETE -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags/{2}' -f $ProjectKey, $RepositoryKey, $tag)
    }
}


