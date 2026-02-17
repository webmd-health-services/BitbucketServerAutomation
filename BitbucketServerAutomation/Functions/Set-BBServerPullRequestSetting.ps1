
function Set-BBServerPullRequestSetting
{
    <#
    .SYNOPSIS
    Sets the pull request settings for a repository.

    .DESCRIPTION
    The `Set-BBServerPullRequestSetting` function sets the specified pull request settings for a Bitbucket Server repository.

    .EXAMPLE
    Set-BBServerPullRequestSetting -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo' -RequiredApprovers 2 -RequiredAllApprovers

    Demonstrates how to set the pull request settings in the `TestRepo` repository as follows:
        Minimum of 2 approvers must approve; All selected approvers must approve

    .EXAMPLE
    Set-BBServerPullRequestSetting -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo' -RequiredApprovers 1 -UnapproveOnUpdate $false

    Demonstrates how to set the pull request settings in the `TestRepo` repository as follows:
        Minimum of 1 approver must approve; Prior approvals will *not* be removed if the pull request is updated.
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

        # The name of a specific repository.
        [Parameter(Mandatory)]
        [String] $RepoName,

        # The minimum number of users that must approve a pull request before it can be merged.
        [int] $RequiredApprovers,

        # Whether or not all approvers must approve a pull request before it can be merged.
        [bool] $RequiredAllApprovers,

        # Whether or not reviewers approvals will be removed if new commits are pushed or the pull request is retargeted
        # to a different branch.
        [bool] $UnapproveOnUpdate
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/settings/pull-requests' -f $ProjectKey, $RepoName)
    $pullRequestSettingConfig = @{}

    if( $RequiredApprovers )
    {
        $pullRequestSettingConfig += @{ requiredApprovers = $RequiredApprovers }
    }

    if( $MyInvocation.BoundParameters.ContainsKey('RequiredAllApprovers') )
    {
        if( $RequiredAllApprovers )
        {
            $pullRequestSettingConfig += @{ requiredAllApprovers = $true }
        }
        else
        {
            $pullRequestSettingConfig += @{ requiredAllApprovers = $false }
        }
    }

    if( $MyInvocation.BoundParameters.ContainsKey('UnapproveOnUpdate') )
    {
        if( $UnapproveOnUpdate )
        {
            $pullRequestSettingConfig += @{ unapproveOnUpdate = $true }
        }
        else
        {
            $pullRequestSettingConfig += @{ unapproveOnUpdate = $false }
        }
    }

    $pullRequestSettings = Invoke-BBServerRestMethod -Session $Session -Method 'POST' -ApiName 'api' -ResourcePath $resourcePath -InputObject $pullRequestSettingConfig

    return $pullRequestSettings
}
