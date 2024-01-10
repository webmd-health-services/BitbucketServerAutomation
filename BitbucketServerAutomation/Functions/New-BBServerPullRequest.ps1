
function New-BBServerPullRequest
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,
        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the branch that you wish to merge from
        $From,
        [Parameter(Mandatory=$true)]
        [string]
        # The name of destination branch
        $To,
        [Parameter(Mandatory=$true)]
        [string]
        # The title of the pull request you wish to create, this cannot be blank.
        $Title
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

    return $Body | Invoke-BBServerRestMethod -Connection $Connection -Method 'POST' -ApiName 'api' -ResourcePath $ResourcePath
}
