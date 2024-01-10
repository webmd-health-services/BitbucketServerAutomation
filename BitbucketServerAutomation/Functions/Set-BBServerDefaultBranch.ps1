
function Set-BBServerDefaultBranch
{
    <#
    .SYNOPSIS
    Sets the default branch in a repository.

    .DESCRIPTION
    The `Set-BBServerDefaultBranch` function sets the specified branch as the default branch in a repository.

    .EXAMPLE
    Set-BBServerDefaultBranch -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -BranchName 'develop'

    Demonstrates how to set the branch named 'develop' as the default branch in the `TestRepo` repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the branch to configure as the default branch.
        $BranchName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/branches/default' -f $ProjectKey, $RepoName)

    $getCurrentBranch = Get-BBServerBranch -Connection $Connection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $BranchName
    if( !$getCurrentBranch )
    {
        Write-Error -Message ('A branch with the name ''{0}'' does not exist in the ''{1}'' repository and cannot be set as the default. Use the `New-BBServerBranch` function to create new branches.' -f $BranchName, $RepoName)
        return
    }

    $defaultBranchConfig = @{ id = $getCurrentBranch.id }
    $setDefaultBranch = Invoke-BBServerRestMethod -Connection $Connection -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath -InputObject $defaultBranchConfig

    $getCurrentBranch = Get-BBServerBranch -Connection $Connection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $BranchName
    return $getCurrentBranch
}
