
function Get-BBServerPullRequest
{
    <#
    .SYNOPSIS
    Gets pull requests.

    .DESCRIPTION
    The `Get-BBServerPullRequest` function gets all pull requests in a Bitbucket Server instance. If you pass it an id,
    it will get just the pull request with that id.

    .EXAMPLE
    Get-BBServerPullRequest -Session $session -ProjectKey $projectKey -RepoName $repoName -ID $ID

    Demonstrates how to get a specific pull request from a repository using the pull request ID.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The id of the pull request to get, if this is not included the default will be to get all current pull requests
        [String] $ID = "",

        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The name of a specific repository.
        [Parameter(Mandatory)]
        [String] $RepoName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ResourcePath = ('projects/{0}/repos/{1}/pull-requests/{2}' -f $ProjectKey, $RepoName, $ID)

    return Invoke-BBServerRestMethod -Session $Session -Method Get -ApiName 'api' -ResourcePath $ResourcePath
}
