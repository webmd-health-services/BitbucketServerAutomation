
function Get-BBServerChange
{
    <#
    .SYNOPSIS
    Gets a list of Changes from two commits in a repository.

    .DESCRIPTION
    The `Get-BBServerChange` function returns a list of Changes from two commits in a repository.

    .EXAMPLE
    Get-BBServerChange -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo' -From "TestBranch" -To "master"

    Demonstrates how to get the properties of all changes between testBranch and master branches in the `TestRepo` repository.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [object] $Session,

        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        [Parameter(Mandatory)]
        [string] $ProjectKey,

        # The name of a specific repository.
        [Parameter(Mandatory)]
        [string] $RepoName,

        # name of the source commit or Ref.
        [Parameter(Mandatory)]
        [string] $From,

        # name of the target commit or Ref.
        [Parameter(Mandatory)]
        [string] $To
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $lastPage = $false
    $nextPageStart = 0
    $changes = $null

    while ( -not $lastPage )
    {
        $resourcePath = ('projects/{0}/repos/{1}/compare/changes?from={2}&to={3}' -f $ProjectKey, $RepoName, [Web.HttpUtility]::UrlEncode($From), [Web.HttpUtility]::UrlEncode($To))
        $changes = Invoke-BBServerRestMethod -Session $Session `
                                             -Method Get `
                                             -ApiName 'api' `
                                             -ResourcePath ('{0}&limit={1}&start={2}' -f $resourcePath, [int16]::MaxValue, $nextPageStart)
        if( $changes)
        {
            $lastPage = $changes.isLastPage
            $nextPageStart = $changes.nextPageStart
            return $changes.values
            continue
        }
        return
    }
}
