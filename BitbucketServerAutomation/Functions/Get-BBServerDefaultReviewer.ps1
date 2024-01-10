
function Get-BBServerDefaultReviewer
{
    <#
    .SYNOPSIS
    Gets the default reviewer conditions for a project or repository.

    .DESCRIPTION
    The `Get-BBServerDefaultReviewer` function gets the default reviewer conditions that have been configured at either the project or repository level. When getting the default reviewer conditions for a repository, any default reviewer conditions inherited from the parent project will also be returned.

    .EXAMPLE
    Get-BBServerDefaultReviewer -Connection $conn -ProjectKey 'GBBSDR'

    Demonstrates getting all the default reviewer conditions that have been configured for the "GBBSDR" project.

    .EXAMPLE
    Get-BBServerDefaultReviewer -Connection $conn -ProjectKey 'GBBSDR' -RepositoryName 'Scripts'

    Demonstrates getting all the default reviewer conditions that have been configured for the "Scripts" repository, including any inherited conditions from its parent "GBBSDR" project.
    #>
    param(
        [Parameter(Mandatory)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting. Use `New-BBServerConnection` to create connection objects.
        $Connection,

        [Parameter(Mandatory)]
        [string]
        # The key/ID that identifies the project. This is *not* the project name.
        $ProjectKey,

        [string]
        # The name of a repository in the project.
        $RepositoryName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $resourcePath = 'projects/{0}/conditions' -f $ProjectKey
    if ($RepositoryName)
    {
        $resourcePath = 'projects/{0}/repos/{1}/conditions' -f $ProjectKey, $RepositoryName
    }

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'default-reviewers' -ResourcePath $resourcePath
}
