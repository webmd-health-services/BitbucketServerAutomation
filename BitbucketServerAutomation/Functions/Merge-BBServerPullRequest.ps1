
function Merge-BBServerPullRequest
{
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The name of a specific repository.
        [Parameter(Mandatory)]
        [String] $RepoName,

        # The ID of the pull request you wish to merge, use the Get-BBServerPullRequest to find the ID
        [Parameter(Mandatory)]
        [String] $ID,

        # The current version of the pull request you wish to merge. Get-BBServerPullRequest returns pull request
        # version information.
        [Parameter(Mandatory)]
        [String] $Version
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Body = @{
        version = $Version;
    }
    $ResourcePath = ('projects/{0}/repos/{1}/pull-requests/{2}/merge' -f $ProjectKey, $RepoName, $ID )

    return $Body | Invoke-BBServerRestMethod -Session $Session -Method 'POST' -ApiName 'api' -ResourcePath $ResourcePath
}
