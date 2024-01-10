
function Get-BBServerUser
{
    <#
    .SYNOPSIS
    Gets a Bitbucket Server user.

    .DESCRIPTION
    The `Get-BBServerUser` function gets users that exist in Bitbucket Server. By default all users are returned.

    To get specific users, pass a string representing a username, display name, or email address to the `Filter` parameter.

    .EXAMPLE
    Get-BBServerUser -Connection $BBConnection

    Demonstrates how to get all Bitbucket Server users.

    .EXAMPLE
    Get-BBServerUser -Connection $BBConnection -Filter 'email.com'

    Demonstrates how to get all Bitbucket Server users whose email address contains "email.com".
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [string]
        # Filter to use to find a specific user. This is passed to Bitbucket Server as-is. It searches a user's username, display name, and email address for the filter. If any field matches, that user is returned.
        $Filter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $requestQueryParameter = @{}
    if ($Filter)
    {
        $requestQueryParameter['Parameter'] = @{ 'filter' = $Filter }
    }

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath 'admin/users' -IsPaged @requestQueryParameter
}
