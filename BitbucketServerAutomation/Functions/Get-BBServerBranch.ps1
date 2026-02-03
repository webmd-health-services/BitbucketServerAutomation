
function Get-BBServerBranch
{
    <#
    .SYNOPSIS
    Gets a list of branches from a repository.

    .DESCRIPTION
    The `Get-BBServerBranch` function returns a list of all branches in a Bitbucket Server repository.

    If you pass a branch name, the function will only return the information for the named branch and will return
    nothing if no branches are found that match the search criteria. Wildcards are allowed to search for files.

    .EXAMPLE
    Get-BBServerBranch -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo'

    Demonstrates how to get the properties of all branches in the `TestRepo` repository.

    .EXAMPLE
    Get-BBServerBranch -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo' -BranchName 'master'

    Demonstrates how to get the properties for the master branch in the `TestRepo` repository.
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

        # The name of the branch to search for.
        [String] $BranchName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/branches' -f $ProjectKey, $RepoName)

    $getBranches =
        Invoke-BBServerRestMethod -Session $Session -Method 'GET' -ApiName 'api' -ResourcePath $resourcePath -IsPaged

    if( $BranchName )
    {
        return $getBranches | Where-Object { $_.displayId -like $BranchName }
    }

    return $getBranches
}
