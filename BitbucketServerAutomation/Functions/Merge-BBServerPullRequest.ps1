
function Merge-BBServerPullRequest
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,
        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,
        [Parameter(Mandatory=$true)]
        [string]
        # this is the ID of the pull request you wish to merge, use the Get-BBServerPullRequest to find the ID
        $ID,
        [Parameter(Mandatory=$true)]
        [string]
        # this is to specify the current version of the pull request you wish to merge. you can get the version of the pull request from Get-BBServerPullRequest
        $Version
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Body = @{
        version = $Version;
    }
    $ResourcePath = ('projects/{0}/repos/{1}/pull-requests/{2}/merge' -f $ProjectKey, $RepoName, $ID )

    return $Body | Invoke-BBServerRestMethod -Connection $Connection -Method 'POST' -ApiName 'api' -ResourcePath $ResourcePath
}
