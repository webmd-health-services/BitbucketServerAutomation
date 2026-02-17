
function New-BBServerBranch
{
    <#
    .SYNOPSIS
    Creates a new branch in a repository.

    .DESCRIPTION
    The `New-BBServerBranch` function creates a new branch in a repository if it does not already exist. If the specified branch already exists, the function will do nothing.

    .EXAMPLE
    New-BBServerBranch -Session $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -BranchName 'develop' -StartPoint 'master'

    Demonstrates how to create a branch named 'develop' in in the `TestRepo` repository. The new branch will start in the current state of the existing 'master' branch
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

        # The name of the branch to create.
        [Parameter(Mandatory)]
        [String] $BranchName,

        # The existing branch name or hash id of the commit/changeset to use as the HEAD of the new branch.
        [Parameter(Mandatory)]
        [String] $StartPoint
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resourcePath = ('projects/{0}/repos/{1}/branches' -f $ProjectKey, $RepoName)

    $checkBranchExists = Get-BBServerBranch -Session $Session -ProjectKey $ProjectKey -RepoName $RepoName -BranchName $BranchName
    if( $checkBranchExists )
    {
        Write-Error -Message ('A branch with the name ''{0}'' already exists in the ''{1}'' repository. No new branch will be created.' -f $BranchName, $RepoName)
        return
    }

    $newBranchConfig = @{ name = $BranchName ; startPoint = $StartPoint }
    $newBranch = Invoke-BBServerRestMethod -Session $Session -Method 'POST' -ApiName 'api' -ResourcePath $resourcePath -InputObject $newBranchConfig

    return $newBranch
}
