
function Enable-BBServerHook
{
    <#
    .SYNOPSIS
    Enables a hook in a repository.

    .DESCRIPTION
    The `Enable-BBServerHook` function sets the value of the `Enabled` property to `true` for a designated hook in a
    Bitbucket Server repository.

    If you pass a hook key that does not exist in the target repository, an error will be thrown.

    .EXAMPLE
    Enable-BBServerHook -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo' -HookKey 'com.atlassian.bitbucket.server.example-hook-key'

    Demonstrates how to enable a hook with key `com.atlassian.bitbucket.server.example-hook-key` in the `TestRepo`
    repository.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        [Parameter(Mandatory)]
        # The name of a specific repository.
        [String] $RepoName,

        # The name of the repository hook to enable.
        [Parameter(Mandatory)]
        [String] $HookKey
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/settings/hooks/{2}/enabled' -f $ProjectKey, $RepoName, $HookKey)

    Invoke-BBServerRestMethod -Session $Session -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath
}
