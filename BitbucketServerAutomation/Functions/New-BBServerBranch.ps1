
function New-BBServerBranch
{
    <#
    .SYNOPSIS
    Creates a new branch in a repository.

    .DESCRIPTION
    The `New-BBServerBranch` function creates a new branch in a repository if it does not already exist. If the specified branch already exists, the function will do nothing.

    .EXAMPLE
    New-BBServerBranch -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -BranchName 'develop' -StartPoint 'master'

    Demonstrates how to create a branch named 'develop' in in the `TestRepo` repository. The new branch will start in the current state of the existing 'master' branch
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
        # The name of the branch to create.
        $BranchName,

        [Parameter(Mandatory=$true)]
        [string]
        # The existing branch name or hash id of the commit/changeset to use as the HEAD of the new branch.
        $StartPoint
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/branches' -f $ProjectKey, $RepoName)

    $checkBranchExists = Get-BBServerBranch -Connection $Connection -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $BranchName
    if( $checkBranchExists )
    {
        Write-Error -Message ('A branch with the name ''{0}'' already exists in the ''{1}'' repository. No new branch will be created.' -f $BranchName, $RepoName)
        return
    }

    $newBranchConfig = @{ name = $BranchName ; startPoint = $StartPoint }
    $newBranch = Invoke-BBServerRestMethod -Connection $Connection -Method 'POST' -ApiName 'api' -ResourcePath $resourcePath -InputObject $newBranchConfig

    return $newBranch
}
