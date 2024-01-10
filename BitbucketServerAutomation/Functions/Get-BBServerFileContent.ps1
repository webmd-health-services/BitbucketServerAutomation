
function Get-BBServerFileContent
{
    <#
    .SYNOPSIS
    Gets the raw content of a file in a repository.

    .DESCRIPTION
    The `Get-BBServerFileContent` function gets the raw content of a file from a repository. Pass the connection to the
    Bitbucket Server to the `Connection` object. Pass the project key of the repository to the `ProjectKey` parameter.
    Pass the repository name to the `RepoName` parameter. Pass the path to the file in the repository to the `Path`
    parameter. The raw content of the file is returned.

    To retrieve the value of the file at a specific commit, pass the commitish identifier (a tag, hash, branch name,
    etc.) to the `Commitish` parameter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        [Object] $Connection,

        [Parameter(Mandatory)]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        [String] $ProjectKey,

        [Parameter(Mandatory)]
        # The name of a specific repository.
        [String] $RepoName,

        [Parameter(Mandatory)]
        # The path of the file in the repository. Use forward-slashes for directory separators.
        [String] $Path,

        # The commit at which to get the file's contents.
        [String] $Commitish
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Path = "projects/$($ProjectKey)/repos/$($RepoName)/raw/$($Path)"

    $parameter = @{}
    if( $Commitish )
    {
        $parameter['at'] = $Commitish
    }

    Invoke-BBServerRestMethod -Connection $Connection `
                              -Method Get `
                              -ApiName 'api' `
                              -ResourcePath $Path `
                              -Parameter $parameter `
                              -Raw
}