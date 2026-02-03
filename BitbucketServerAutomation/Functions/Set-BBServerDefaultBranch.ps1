
function Set-BBServerDefaultBranch
{
    <#
    .SYNOPSIS
    Sets the default branch in a repository.

    .DESCRIPTION
    The `Set-BBServerDefaultBranch` function sets the specified branch as the default branch in a repository.

    .EXAMPLE
    Set-BBServerDefaultBranch -Session $session -ProjectKey 'TestProject' -RepoName 'TestRepo' -BranchName 'develop'

    Demonstrates how to set the branch named 'develop' as the default branch in the `TestRepo` repository.
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

        # The name of the branch to configure as the default branch.
        [Parameter(Mandatory)]
        [String] $BranchName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/branches/default' -f $ProjectKey, $RepoName)

    $getCurrentBranch = Get-BBServerBranch -Session $Session -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $BranchName
    if( !$getCurrentBranch )
    {
        Write-Error -Message ('A branch with the name ''{0}'' does not exist in the ''{1}'' repository and cannot be set as the default. Use the `New-BBServerBranch` function to create new branches.' -f $BranchName, $RepoName)
        return
    }

    $defaultBranchConfig = @{ id = $getCurrentBranch.id }
    $setDefaultBranch = Invoke-BBServerRestMethod -Session $Session -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath -InputObject $defaultBranchConfig

    $getCurrentBranch = Get-BBServerBranch -Session $Session -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $BranchName
    return $getCurrentBranch
}
