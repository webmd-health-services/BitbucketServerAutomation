
Set-StrictMode -Version 'Latest'

function New-BBServerTag
{
    [CmdletBinding()]
    param(
 
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,    
 
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository's project.
        $ProjectKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository.
        $RepositoryKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The tag's name/value.
        $Name,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The commit ID the tag should point to. In the Bitbucket Server API documentation, this is called the `startPoint`.
        $CommitID,
 
        [string]
        # An optional message for the commit that creates the tag.
        $Message = "",

        [Switch]
        $Force,

        [String]
        $Type = "LIGHTWEIGHT"
 
    )
 
    Set-StrictMode -Version 'Latest'
 
    #Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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

    $result = $tag | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $ProjectKey, $RepositoryKey)
    if (-not $result)
    {
        throw ("Unable to tag commit {0} with {1}." -f $CommitID, $Name)
    }
}
 