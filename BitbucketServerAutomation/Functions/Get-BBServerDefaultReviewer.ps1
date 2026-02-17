
function Get-BBServerDefaultReviewer
{
    <#
    .SYNOPSIS
    Gets the default reviewer conditions for a project or repository.

    .DESCRIPTION
    The `Get-BBServerDefaultReviewer` function gets the default reviewer conditions that have been configured at either
    the project or repository level. When getting the default reviewer conditions for a repository, any default reviewer
    conditions inherited from the parent project will also be returned.

    .EXAMPLE
    Get-BBServerDefaultReviewer -Session $session -ProjectKey 'GBBSDR'

    Demonstrates getting all the default reviewer conditions that have been configured for the "GBBSDR" project.

    .EXAMPLE
    Get-BBServerDefaultReviewer -Session $session -ProjectKey 'GBBSDR' -RepositoryName 'Scripts'

    Demonstrates getting all the default reviewer conditions that have been configured for the "Scripts" repository,
    including any inherited conditions from its parent "GBBSDR" project.
    #>
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The name of a repository in the project.
        [String] $RepositoryName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $resourcePath = 'projects/{0}/conditions' -f $ProjectKey
    if ($RepositoryName)
    {
        $resourcePath = 'projects/{0}/repos/{1}/conditions' -f $ProjectKey, $RepositoryName
    }

    Invoke-BBServerRestMethod -Session $Session -Method Get -ApiName 'default-reviewers' -ResourcePath $resourcePath
}
