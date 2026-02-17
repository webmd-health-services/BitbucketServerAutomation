
function Remove-BBServerRepository
{
    <#
    .SYNOPSIS
    Remove a repository from Bitbucket Server.

    .DESCRIPTION
    The `Remove-BBServerRepository` deletes a repository from Bitbucket Server. This is a dangerous operation as all
    related data is also deleted. You will have to confirm the deletion. To force the deletion without being confirmed,
    use the `Force` switch.

    Use the `New-BBServerSession` function to create a Session object to pass to the `Session` parameter.

    .EXAMPLE
    Remove-BBServerRepository -Session $session -ProjectKey 'BBSA' -Name 'fubarsnafu'

    Demonstrates how to delete a repository. Because deleting a repository is a high-impact operation, you will asked to
    confirm the deletion.

    .EXAMPLE
    Remove-BBServerRepository -Session $session -ProjectKey 'BBSA' -Name 'fubarsnafu' -Force

    Demonstrates how to delete a repository, skipping any confirmation dialogs. This can be dangerous since deletions
    can't be undone. Use the `Force` switch with care.

    .EXAMPLE
    Get-BBServerRepository -Session $session -ProjectKey 'BBSA' -Name 'snafu' | Remove-BBServerRepository -Session $session

    Demonstrates that you can pipe objects returned by `Get-BBServerRepository` to `Remove-BBServerRepository`. When you
    pipe repository objects, you don't have to provide the project key

    .EXAMPLE
    'fubarsnafu' | Remove-BBServerRepository -Session $session -ProjectKey 'BBSA'

    Demonstrates that you can pipe repository names to `Remove-BBServerRepository`. When you do, you *must* also provide
    the project key.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="High")]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        [String] $ProjectKey,

        # The name of a specific repository to get.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Name,

        # Don't prompt the user to confirm the deletion of the repository. This is a dangerous switch to use, since
        # repository deletions can't be undone.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( $Name.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo' )
        {
            $repoInfo = $Name
            $Name = $repoInfo.name
            if( -not $Name )
            {
                Write-Error -Message ('Repository name not found. Looks like you piped in an invalid repository object because either we can''t find the `name` property or it doesn''t have a value.')
                return
            }

            $ProjectKey = $repoInfo.project.key
            if( -not $ProjectKey )
            {
                Write-Error -Message ('Project key not found. Looks like you piped in an invalid repository object becuse either the `project.key` properties don''t exist or they don''t have values.')
                return
            }
        }

        if( -not $ProjectKey )
        {
            Write-Error -Message ('ProjectKey parameter missing. When passing the name of a repository with the Name parameter you must also pass the repository''s project key with the ProjectKey parameter.')
            return
        }

        $whatIfMessage = 'removing repository ''{0}/{1}'' from {2}' -f $ProjectKey,$Name,$Session.Url
        $confirmMessage = 'Do you want to remove repository ''{0}/{1}'' from {2}?{3}{3}This operation is PERMANENT and can''t be undone!' -f $ProjectKey,$Name,$Session.Url,[Environment]::NewLine
        if( $Force -or $PSCmdlet.ShouldProcess($whatIfMessage,$confirmMessage,'Confirm Permanently Deleting Repository') )
        {
            $result = Invoke-BBServerRestMethod -Session $Session -Method Delete -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}' -f $projectKey,$Name)

            if( $result )
            {
                $result | ConvertTo-Json | Write-Verbose
            }
        }
    }
}
