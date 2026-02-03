
function Get-BBServerFileContent
{
    <#
    .SYNOPSIS
    Gets the raw content of a file in a repository.

    .DESCRIPTION
    The `Get-BBServerFileContent` function gets the raw content of a file from a repository. Pass the session to the
    Bitbucket Server to the `Session` object. Pass the project key of the repository to the `ProjectKey` parameter.
    Pass the repository name to the `RepoName` parameter. Pass the path to the file in the repository to the `Path`
    parameter. The raw content of the file is returned.

    To retrieve the value of the file at a specific commit, pass the commitish identifier (a tag, hash, branch name,
    etc.) to the `Commitish` parameter.
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

        # The path of the file in the repository. Use forward-slashes for directory separators.
        [Parameter(Mandatory)]
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

    Invoke-BBServerRestMethod -Session $Session `
                              -Method Get `
                              -ApiName 'api' `
                              -ResourcePath $Path `
                              -Parameter $parameter `
                              -Raw
}