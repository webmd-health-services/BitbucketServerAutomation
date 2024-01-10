
function Get-BBServerPullRequestSetting
{
    <#
    .SYNOPSIS
    Gets a list of pull request settings from a repository.

    .DESCRIPTION
    The `Get-BBServerPullRequestSetting` function returns a list of all pull request settings in a Bitbucket Server repository.

    If you pass a setting name, the function will only return the information for the named setting. It will return an error if no setting exists that match the search criteria.

    .EXAMPLE
    Get-BBServerPullRequestSetting -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo'

    Demonstrates how to get all pull request settings in the `TestRepo` repository.

    .EXAMPLE
    Get-BBServerPullRequestSetting -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -SettingName 'RequiredApprovers'

    Demonstrates how to get `RequiredApprovers` setting in the `TestRepo` repository.
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

        [string]
        # The name of the pull request setting to retrieve. When omitted, all settings are returned.
        $SettingName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/settings/pull-requests' -f $ProjectKey, $RepoName)
    $pullRequestSettings = Invoke-BBServerRestMethod -Connection $Connection -Method 'GET' -ApiName 'api' -ResourcePath $resourcePath

    if( $SettingName )
    {
        try
        {
            return $pullRequestSettings.('{0}' -f $SettingName)
        }
        catch
        {
            Write-Error ('''{0}'' is not a valid Pull Request configuration setting. Please enter a valid setting or omit the $SettingName parameter to return all settings.' -f $SettingName)
            return
        }
    }
    else
    {
        return $pullRequestSettings
    }
}
