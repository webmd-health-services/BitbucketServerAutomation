
function New-BBServerDefaultReviewer
{
    <#
    .SYNOPSIS
    Creates a new default reviewer pull request condition for a project or repository.

    .DESCRIPTION
    The `New-BBServerDefaultReviewer` function creates a default reviewer pull request condition for a given project or repository. A new default reviewer condition is always created, even if an existing one with identical parameters exists.

    Pass Bitbucket Server user objects to the `User` parameter (use `Get-BBServerUser` to get user objects). Pass the number of required approvals to the `ApprovalCount` parameter (must be less than or equal to number of `User`).

    By default, the default reviewer condition will be created at the project level with a Source and Target branch of "Any". To create a default reviewer condition for a repository, pass the name of a repository to the `RepositoryName` parameter.

    When `SourceBranchType`/`TargetBranchType` is `Model`, the `SourceBranchValue`/`TargetBranchValue` parameter argument **must** be one of: `Feature`, `Bugfix`, `Hotfix`, `Release`, `Development`, `Production`

    .EXAMPLE
    New-BBServerDefaultReviewer -Connection $conn -ProjectKey 'NBBSDR' -User (Get-BBServerUser -Connection $conn -Filter 'samiam@example.com') -ApprovalCount 1

    Demonstrates creating a new default reviewer pull request condition for user with email "samiam@example.com" and required approval count of `1`. The source and target matching branches will be default of `Any`.

    .EXAMPLE
    New-BBServerDefaultReviewer -Connection $conn -ProjectKey 'NBBSDR' -User $requiredReviewers -ApprovalCount 3 -TargetBranchType 'Name' -TargetBranchValue 'master'

    Demonstrates creating a new default reviewer condition for a collection of users and required approval count of `3` for any pull request that targets the `master` branch.

    .EXAMPLE
    New-BBServerDefaultReviewer -Connection $conn -ProjectKey 'NBBSDR' -User $requiredReviewers -ApprovalCount 0 -SourceBranchType 'Pattern' -SourceBranchValue 'feature/*' -TargetBranchType 'Model' -TargetBranchValue 'Development'

    Demonstrates creating a new default reviewer condition for a collection of users and require no approvals for any pull request that comes from a `feature/*` branch and targets the `Development` model branch configured for a repository.

    .EXAMPLE
    New-BBServerDefaultReviewer -Connection $conn -ProjectKey 'NBBSDR' -User $requiredReviewers -ApprovalCount 3 -RepositoryName 'Web Service Application' -TargetBranchType 'Name' -TargetBranchValue 'master'

    Demonstrates creating a new default reviewer condition for a collection of users and required approval count of `3` for any pull request that targets the `master` branch in the repository named "Web Service Application".
    #>
    param(
        [Parameter(Mandatory)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting. Use `New-BBServerConnection` to create connection objects.
        $Connection,

        [Parameter(Mandatory)]
        [string]
        # The key/ID that identifies the project. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory)]
        [object[]]
        # Collection of objects representing the users to add to the default reviewer condition. Use `Get-BBServerUser` to get Bitbucket Server user objects.
        $User,

        [Parameter(Mandatory)]
        [int]
        # The number of default reviewers that must approve a pull request.
        $ApprovalCount,

        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        # The type of matching for the source branch.
        $SourceBranchType = 'Any',

        [string]
        # Specifies the value or pattern to match a source branch, if `-SourceBranchType` is not "Any".
        $SourceBranchValue,

        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        # The type of matching for the target branch.
        $TargetBranchType = 'Any',

        [string]
        # Specifies the value or pattern to match a target branch, if `-TargetBranchType` is not "Any".
        $TargetBranchValue,

        [string]
        # The name of a repository in the project.
        $RepositoryName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $sourceMatcherConfig = Get-DefaultReviewerBranchMatcher -TypeParameterName 'SourceBranchType' -ValueParameterName 'SourceBranchValue' -Type $SourceBranchType -Value $SourceBranchValue
    if (-not $sourceMatcherConfig)
    {
        return
    }

    $targetMatcherConfig = Get-DefaultReviewerBranchMatcher -TypeParameterName 'TargetBranchType' -ValueParameterName 'TargetBranchValue' -Type $TargetBranchType -Value $TargetBranchValue
    if (-not $targetMatcherConfig)
    {
        return
    }

    $userCount = $User | Measure-Object | Select-Object -ExpandProperty 'Count'
    if ($ApprovalCount -gt $userCount)
    {
        Write-Error -Message ('"ApprovalCount" ({0}) must be less than or equal to the number of users passed to the "User" parameter ({1}).' -f $ApprovalCount, $userCount) -ErrorAction $ErrorActionPreference
        return
    }

    $idx = -1
    $userProperties = @('name', 'emailAddress', 'id', 'displayName', 'active', 'slug', 'type')
    foreach ($userObj in $User)
    {
        $idx++
        foreach ($property in $userProperties)
        {
            if (-not ($userObj | Get-Member -Name $property))
            {
                Write-Error -Message ('User[{0}] doesn''t have a "{1}" property. Make sure you''re using the "Get-BBServerUser" function to get users.' -f $idx, $property) -ErrorAction $ErrorActionPreference
                return
            }
        }
    }

    $requestBody = @{
        reviewers = @($User | Select-Object -Property $userProperties)
        sourceMatcher = $sourceMatcherConfig
        targetMatcher = $targetMatcherConfig
        requiredApprovals = $ApprovalCount
    }

    $resourcePath = 'projects/{0}' -f $ProjectKey
    if ($RepositoryName)
    {
        $resourcePath = '{0}/repos/{1}' -f $resourcePath,$RepositoryName
    }
    $resourcePath = '{0}/condition' -f $resourcePath

    $requestBody | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'default-reviewers' -ResourcePath $resourcePath
}
