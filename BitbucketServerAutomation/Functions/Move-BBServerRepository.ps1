
function Move-BBServerRepository
{
    <#
    .SYNOPSIS
    Move a repository in Bitbucket Server from one project to another.

    .DESCRIPTION
    The `Move-BBServerRepository` moves a repository in Bitbucket Server.

    Use the `New-BBServerSession` function to create a Session object to pass to the `Session` parameter.

    .EXAMPLE
    Move-BBServerRepository -Session $session -ProjectKey 'BBSA' -RepoName 'fubarsnafu' -TargetProjectKey 'BBSA_NEW'

    Demonstrates how to move the repository 'fubarsnafu' from the 'BBSA' project to the 'BBSA_NEW'
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

        # The name of a specific repository to move to the new project.
        [Parameter(Mandatory)]
        [Object] $RepoName,

        # The key/ID that identifies the target project where the repository will be moved. This is *not* the project
        # name.
        [Parameter(Mandatory)]
        [String] $TargetProjectKey
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}' -f $ProjectKey, $RepoName)

    $getProjects = Get-BBServerProject -Session $Session

    $currentProject = $getProjects | Where-Object { $_.key -eq $ProjectKey }
    if( !$currentProject )
    {
        Write-Error -Message ('A project with key/ID ''{0}'' does not exist. Specified repository cannot be moved.' -f $ProjectKey)
        return
    }

    $targetProject = $getProjects | Where-Object { $_.key -eq $TargetProjectKey }
    if( !$targetProject )
    {
        Write-Error -Message ('A project with key/ID ''{0}'' does not exist. Specified repository cannot be moved.' -f $TargetProjectKey)
        return
    }

    $currentRepo = Get-BBServerRepository -Session $Session -ProjectKey $ProjectKey | Where-Object { $_.name -eq $RepoName }
    if( !$currentRepo )
    {
        Write-Error -Message ('A repository with name ''{0}'' does not exist in the project ''{1}''. Specified respository cannot be moved.' -f $RepoName, $ProjectKey)
        return
    }

    $repoProjectConfig = @{ project = @{ key = $TargetProjectKey } }
    $setRepoProject = Invoke-BBServerRestMethod -Session $Session -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath -InputObject $repoProjectConfig

    return $setRepoProject
}
