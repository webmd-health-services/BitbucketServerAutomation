
function New-BBServerTag
{
    <#
    .SYNOPSIS
    Creates a new Version Tag on a commit in Bitbucket Server.

    .DESCRIPTION
    The `New-BBServerTag` function creates a new Git Tag with Version information on a commit in Bitbucket Server. It
    requires a commit to exist in a repository, and a project to exist where the repository should live (all
    repositories in Bitbucket Server are part of a project).

    By default, the tag will be lightweight and will not contain a tag message. However, those properties can both be
    overridden with their respective parameters. To add a message to the Tag, utilize the $Message parameter, and if you
    would prefer to use an annotated tag, use the parameter $Type = 'ANNOTATED'

    Use the `New-BBServerSession` function to generate the Session object, `New-BBServerRepository` to generate the
    repository object, and `New-BBServerProject` to generate the project, which should be passed in as the `$Session`,
    `$RepositoryKey`, and `$ProjectKey` parameters.

    The `$Force` parameter will allow the user to force the tag to be generated for that commit regardless of the tags
    use on other commits in the repo.

    .EXAMPLE
    New-BBServerTag -Session $session -ProjectKey $key -RepositoryKey $repoName -name $TagName -CommitID $commitHash

    Demonstrates the default behavior of tagging a commit with a version tag.

    .EXAMPLE
    New-BBServerTag -Session $session -ProjectKey $key -RepositoryKey $repoName -name $TagName -CommitID $commitHash -Message 'Tag Message' -Force -Type 'ANNOTATED'

    Demonstrates how to tag a commit with an annotated tag containing a tag message with the force parameter enabled.
    #>

    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key of the repository's project.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The key of the repository.
        [Parameter(Mandatory)]
        [String] $RepositoryKey,

        # The tag's name/value.
        [Parameter(Mandatory)]
        [String] $Name,

        # The commit ID the tag should point to. In the Bitbucket Server API documentation, this is called the `startPoint`.
        [Parameter(Mandatory)]
        [String] $CommitID,

        # An optional message for the commit that creates the tag.
        [String] $Message = "",

        [switch] $Force,

        [String] $Type = "LIGHTWEIGHT"

    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $tag = @{
                name = $Name
                startPoint = $CommitID
                message = $Message
                type = $Type
                }
    if( $Force )
    {
        $tag['force'] = "true"
    }

    $result = $tag | Invoke-BBServerRestMethod -Session $Session -Method Post -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $ProjectKey, $RepositoryKey)
    if (-not $result)
    {
        Write-Error ("Unable to tag commit {0} with {1}." -f $CommitID, $Name)
    }
}
