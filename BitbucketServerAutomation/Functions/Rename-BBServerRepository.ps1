
function Rename-BBServerRepository
{
    <#
    .SYNOPSIS
    Rename a repository in Bitbucket Server.

    .DESCRIPTION
    The `Rename-BBServerRepository` renames a repository in Bitbucket Server.

    Use the `New-BBServerSession` function to create a session object to pass to the `Session` parameter.

    .EXAMPLE
    Rename-BBServerRepository -Session $session -ProjectKey 'BBSA' -RepoName 'fubarsnafu' -TargetRepoName 'snafu_fubar'

    Demonstrates how to rename a repository from 'fubarsnafu' to 'snafu_fubar'.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project where the repository currently resides. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The name of a specific repository to rename.
        [Parameter(Mandatory)]
        [Object] $RepoName,

        # The target name that the repository will be renamed to.
        [Parameter(Mandatory)]
        [String] $TargetRepoName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}' -f $ProjectKey, $RepoName)

    $getRepos = Get-BBServerRepository -Session $Session -ProjectKey $ProjectKey

    $currentRepo = $getRepos | Where-Object { $_.name -eq $RepoName }
    if( !$currentRepo )
    {
        Write-Error -Message ('A repository with name ''{0}'' does not exist in the project ''{1}''. Specified respository cannot be renamed.' -f $RepoName, $ProjectKey)
        return
    }

    $targetRepo = $getRepos | Where-Object { $_.name -eq $TargetRepoName }
    if( $targetRepo )
    {
        Write-Error -Message ('A repository with name ''{0}'' already exists in the project ''{1}''. Specified respository cannot be renamed.' -f $TargetRepoName, $ProjectKey)
        return
    }

    $repoRenameConfig = @{ name = $TargetRepoName }
    $setRepoName = Invoke-BBServerRestMethod -Session $Session -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath -InputObject $repoRenameConfig

    return $setRepoName
}
