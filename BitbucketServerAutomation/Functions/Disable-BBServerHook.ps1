
function Disable-BBServerHook
{
    <#
    .SYNOPSIS
    Disables a hook in a repository.

    .DESCRIPTION
    The `Disable-BBServerHook` function sets the value of the `Enabled` property to `false` for a designated hook in a Bitbucket Server repository.

    If you pass a hook key that does not exist in the target repository, an error will be thrown.

    .EXAMPLE
    Disable-BBServerHook -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -HookKey 'com.atlassian.bitbucket.server.example-hook-key'

    Demonstrates how to disable a hook with key `com.atlassian.bitbucket.server.example-hook-key` in the `TestRepo` repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the repository hook to disable.
        $HookKey
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/settings/hooks/{2}/enabled' -f $ProjectKey, $RepoName, $HookKey)

    Invoke-BBServerRestMethod -Connection $Connection -Method 'DELETE' -ApiName 'api' -ResourcePath $resourcePath
}
