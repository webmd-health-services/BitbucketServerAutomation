
function New-BBServerPullRequest
{
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The name of a specific repository.
        [Parameter(Mandatory)]
        [String] $RepoName,

        # The name of the branch that you wish to merge from
        [Parameter(Mandatory)]
        [String] $From,

        # The name of destination branch
        [Parameter(Mandatory)]
        [String] $To,

        # The title of the pull request you wish to create, this cannot be blank.
        [Parameter(Mandatory)]
        [String] $Title
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $Body = @{
        title = $Title;
        state = 'OPEN';
        open = $true;
        closed = $false;
        fromRef = @{
            id = $From;
            repository = @{
                slug = $RepoName;
                name = $null;
                project = @{
                    key = $ProjectKey
                };
            };
        };
        toRef = @{
            id = $To;
            repository = @{
                slug = $RepoName;
                name = $null;
                project = @{
                    key = $ProjectKey
                };
            };
        };
        locked = $false;
        reviewers = $null;
        links = @{
            self = @();
        };
    };
    $ResourcePath = ('projects/{0}/repos/{1}/pull-requests' -f $ProjectKey, $RepoName)

    return $Body | Invoke-BBServerRestMethod -Session $Session -Method 'POST' -ApiName 'api' -ResourcePath $ResourcePath
}
