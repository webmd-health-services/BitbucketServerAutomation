
function Get-BBServerProject
{
    <#
    .SYNOPSIS
    Gets projects.

    .DESCRIPTION
    The `Get-BBServerProject` function gets all projects in a Bitbucket Server instance. If you pass it a name, it will
    get just that project. Wildcards are allowed to search for projects. Wildcard matching is *not* supported by the
    Bitbucket Server API, so all projects must be retrieved and searched.

    .LINK
    https://confluence.atlassian.com/bitbucket/projects-792497956.html

    .EXAMPLE
    Get-BBServerProject -Session $session

    Demonstrates how to get all the projects in an instance of Bitbucket Server.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The name of the project to get. Wildcards allowed. The wildcard search is done on the *client* (i.e. this
        # computer) not the server. All projects are fetched from Bitbucket Server first. This may impact performance.
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = 'projects'
    if( $Name )
    {
        $resourcePath = '{0}?name={1}' -f $resourcePath,$Name
    }
    else
    {
        $resourcePath = '{0}?limit={1}' -f $resourcePath,[int16]::MaxValue
    }

    Invoke-BBServerRestMethod -Session $Session -Method Get -ApiName 'api' -ResourcePath $resourcePath  |
        Select-Object -ExpandProperty 'values' |
        Add-PSTypeName -ProjectInfo
}