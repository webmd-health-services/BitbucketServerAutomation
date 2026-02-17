
function Set-BBServerCommitBuildStatus
{
    <#
    .SYNOPSIS
    Sets the build status of a commit in Bitbucket Server.

    .DESCRIPTION
    The `Set-BBServerCommitBuildStatus` function sets the build status of a specific commit in Bitbucket Server. The
    status can be in progress, successful, or failed. When a build status is set, Bitbucket Server will show a blue "in
    progress" icon for in progress builds, a green checkmark icon for successful builds, and a red failed icon for
    failed builds.

    Data about the commit is read from the environment set up by supported build servers, which is Jenkins. Bitbucket
    Server must have the commit ID, a key that uniquely identifies this specific build, and a URI that points to the
    build's report. The build name is optional, but when running under a supported build server, is also pulled from the
    environment.

    If a commit already has a status, this function will overwrite it.

    .EXAMPLE
    Set-BBServerCommitBuildStatus -Session $session -Status InProgress

    Demonstrates how this function should be called when running under a build server. Currently, Jenkins and TeamCity
    are supported.

    .EXAMPLE
    Set-BBServerCommitBuildStatus -Session $session -Status Successful -CommitID 'e24e50bba38db28fb8cf433d00c0d3372f8405cf' -Key 'jenkins-BitbucketServerAutomation-140' -BuildUri 'https://jenkins.example.com/job/BitbucketServerAutomation/140/' -Name 'BitbucketServerAutomation'

    Demonstrates how to set the build status for a commit using your own custom commit ID, key, and build URI.
    #>
    [CmdletBinding()]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The status of the build.
        [Parameter(Mandatory)]
        [ValidateSet('InProgress','Successful','Failed')]
        $Status,

        # The ID of the commit. The default value is read from environment variables set by build servers.
        #
        # If running under Jenkins, the `GIT_COMMIT` environment variable is used.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write
        # an error and does nothing.
        [ValidateLength(1,255)]
        [String] $CommitID,

        # A value that uniquely identifies the build. The default value is pulled from environment variables that get
        # set by build servers.
        #
        # If running under Jenkins the `BUILD_TAG` environment variable is used.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write
        # an error and does nothing.
        [ValidateLength(1,255)]
        [String] $Key,

        # A URI to the build results. The default is read from the environment variables that get set by build servers.
        #
        # If running under Jenkins, the `BUILD_URL` environment variable is used.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write
        # an error and does nothing.
        [ValidateScript({ $_.ToString().Length -lt 450 })]
        [Uri] $BuildUri,

        # The name of the build. The default value is read from environment variables that get set by build servers.
        #
        # If running under Jenkins, the `JOB_NAME` environment variable is used.
        #
        # If not running under a build server, and none of the above environment variables are set, this function write
        # an error and does nothing.
        [ValidateLength(1,255)]
        [String] $Name,

        # A description of the build. Useful if the state is failed. Default is an empty string.
        [ValidateLength(1,255)]
        [String] $Description = ''
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    # We're in Jenkins
    $body = @{
                state = $Status.ToUpperInvariant();
                description = $Description;
             }
    if( (Test-Path -Path 'env:JENKINS_URL') )
    {
        $body.key = (Get-Item -Path 'env:BUILD_TAG').Value;
        $body.name = (Get-Item -Path 'env:JOB_NAME').Value;
        $body.url = (Get-Item -Path 'env:BUILD_URL').Value;
        if( -not $CommitID )
        {
            $CommitID = (Get-Item -Path 'env:GIT_COMMIT').Value
        }
    }

    if( $PSBoundParameters.ContainsKey('Key') )
    {
        $body['key'] = $Key
    }

    if( $PSBoundParameters.ContainsKey('BuildUri') )
    {
        $body['url'] = $BuildUri
    }

    if( $PSBoundParameters.ContainsKey('Name') )
    {
        $body['name'] = $Name
    }

    $resourcePath = 'commits/{0}' -f $CommitID

    Write-Verbose -Message ('Setting ''{0}'' commit''s build status to ''{1}''.' -f $CommitID,$body.state)
    $body | Invoke-BBServerRestMethod -Session $Session -Method Post -ApiName 'build-status' -ResourcePath $resourcePath
}
