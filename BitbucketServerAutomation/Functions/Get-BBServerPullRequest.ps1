
function Get-BBServerPullRequest
{
    <#
    .SYNOPSIS
    Gets pull requests

    .DESCRIPTION
    The `Get-BBServerPullRequest` function gets all pull requests in a Bitbucket Server instance. If you pass it an id, it will get just the pull request with that id.


    .EXAMPLE
    Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $ID
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [string]
        # The id of the pull request to get, if this is not included the default will be to get all current pull requests
        $ID = "",

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ResourcePath = ('projects/{0}/repos/{1}/pull-requests/{2}' -f $ProjectKey, $RepoName, $ID)

    return Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath $ResourcePath
}
