# Copyright 2019 WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Set-BBServerDefaultReviewer
{
    <#
    .SYNOPSIS
    Updates an existing default reviewer pull request condition for a given project or repository.

    .DESCRIPTION
    The `Set-BBServerDefaultReviewer` function updates the configuration of an existing default reviewer pull request condition for a project or repository. Only the condition parameters you pass to this function will be updated in the existing default reviewer condition, the rest of the parameters in the condition are left as-is.

    You must pass the `ID` of an existing default reviewer condition to this function (use `Get-BBServerDefaultReviewer` to get existing default reviewer conditions). If updating a default reviewer condition for a repository, you must also pass the name of the repository to the `RepositoryName` parameter.

    Pass Bitbucket Server user objects to the `User` parameter (use `Get-BBServerUser` to get user objects). Pass the number of required approvals to the `ApprovalCount` parameter (must be less than or equal to number of given `User` or the existing users configured in the condition).

    When `SourceBranchType`/`TargetBranchType` is `Model`, the `SourceBranchValue`/`TargetBranchValue` parameter argument **must** be one of: `Feature`, `Bugfix`, `Hotfix`, `Release`, `Development`, `Production`

    .EXAMPLE
    Set-BBServerDefaultReviewer -Connection $conn -ProjectKey 'SBBSDR' -ID $existingCondition.id -ApprovalCount 2

    Demonstrates updating an existing default reviewer pull request condition to have a requried approval count of `2`.

    .EXAMPLE
    Set-BBServerDefaultReviewer -Connection $conn -ProjectKey 'SBBSDR' -ID $existingCondition.id -User (Get-BBServerUser -Connection $conn -Filter 'admin') -ApprovalCount 1

    Demonstrates updating an existing default reviewer pull request condition to only have the `admin` user and a required approval count of `1`.

    .EXAMPLE
    Set-BBServerDefaultReviewer -Connection $conn -ProjectKey 'SBBSDR' -ID $existingCondition.id -SourceBranchType 'Any' -TargetBranchType 'Name' -TargetBranchValue 'master'

    Demonstrates updating an existing default reviewer condition to apply to any pull request that targets the `master` branch.

    .EXAMPLE
    Set-BBServerDefaultReviewer -Connection $conn -ProjectKey 'SBBSDR' -ID $existingCondition.id -SourceBranchType 'Pattern' -SourceBranchValue 'hotfix/*' -TargetBranchType 'Model' -TargetBranchValue 'Production'

    Demonstrates updating an existing default reviewer condition to apply to any pull request that originates on a branch matching the pattern `hotfix/*` and targets the configured `Production` model branch.
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
        [int]
        # The ID of the default reviewer condition. Use `Get-BBServerDefaultReviewer` to get the ID of an existing condition.
        $ID,

        [int]
        # The number of default reviewers that must approve a pull request.
        $ApprovalCount,

        [string]
        # The name of a repository in the project.
        $RepositoryName,

        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        # The type of matching to do against the source branch.
        $SourceBranchType,

        [string]
        # Specifies the value or pattern to match a source branch, if `-SourceBranchType` is not "Any".
        $SourceBranchValue,

        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        # The type of matching to do against the target branch.
        $TargetBranchType,

        [string]
        # Specifies the value or pattern to match a target branch, if `-TargetBranchType` is not "Any".
        $TargetBranchValue,

        [object[]]
        # Collection of objects representing the users to add to the default reviewer condition. Use `Get-BBServerUser` to get Bitbucket Server user objects.
        $User
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($SourceBranchValue -and -not $SourceBranchType)
    {
        Write-Error -Message 'You must specify a "SourceBranchType" when giving a "SourceBranchValue".'
        return
    }

    if ($TargetBranchValue -and -not $TargetBranchType)
    {
        Write-Error -Message 'You must specify a "TargetBranchType" when giving a "TargetBranchValue".'
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

    $notFoundErrorMessageSuffix = 'project "{0}"' -f $ProjectKey
    $repositoryParam = @{ }
    if ($RepositoryName)
    {
        $notFoundErrorMessageSuffix = 'repository "{0}" in {1}' -f $RepositoryName, $notFoundErrorMessageSuffix
        $repositoryParam['RepositoryName'] = $RepositoryName
    }

    $existingCondition =
        Get-BBServerDefaultReviewer -Connection $Connection -ProjectKey $ProjectKey @repositoryParam |
        Where-Object { $_ } |
        Where-Object { $_.id -eq $ID }

    if (-not $existingCondition)
    {
        Write-Error -Message ('Default reviewer pull request condition with ID "{0}" does not exist for {1}.' -f $ID, $notFoundErrorMessageSuffix) -ErrorAction $ErrorActionPreference
        return
    }

    $requestBody = [PSCustomObject]@{
        reviewers = @($existingCondition.reviewers | Select-Object -Property $userProperties)
        sourceMatcher = $existingCondition.sourceRefMatcher
        targetMatcher = $existingCondition.targetRefMatcher
        requiredApprovals = $existingCondition.requiredApprovals
    }

    if ($PSBoundParameters.ContainsKey('ApprovalCount'))
    {
        $userCount = $requestBody.reviewers | Measure-Object | Select-Object -ExpandProperty 'Count'
        $tooManyUsersErrorSuffix = 'configured for the condition ({0})' -f $userCount
        if ($User)
        {
            $userCount = $User | Measure-Object | Select-Object -ExpandProperty 'Count'
            $tooManyUsersErrorSuffix = 'passed to the "User" parameter ({0})' -f $userCount
        }

        if ($ApprovalCount -gt $userCount)
        {
            Write-Error -Message ('"ApprovalCount" ({0}) must be less than or equal to the number of users {1}.' -f $ApprovalCount, $tooManyUsersErrorSuffix) -ErrorAction $ErrorActionPreference
            return
        }

        $requestBody.requiredApprovals = $ApprovalCount
    }

    if ($SourceBranchType)
    {
        $sourceMatcherConfig = Get-DefaultReviewerBranchMatcher -TypeParameterName 'SourceBranchType' -ValueParameterName 'SourceBranchValue' -Type $SourceBranchType -Value $SourceBranchValue
        if (-not $sourceMatcherConfig)
        {
            return
        }

        $requestBody.sourceMatcher = $sourceMatcherConfig
    }

    if ($TargetBranchType)
    {
        $targetMatcherConfig = Get-DefaultReviewerBranchMatcher -TypeParameterName 'TargetBranchType' -ValueParameterName 'TargetBranchValue' -Type $TargetBranchType -Value $TargetBranchValue
        if (-not $targetMatcherConfig)
        {
            return
        }

        $requestBody.targetMatcher = $targetMatcherConfig
    }

    if ($User)
    {
        $requestBody.reviewers = @($User | Select-Object -Property $userProperties)
    }

    $resourcePath = 'projects/{0}' -f $ProjectKey
    if ($RepositoryName)
    {
        $resourcePath = '{0}/repos/{1}' -f $resourcePath,$RepositoryName
    }
    $resourcePath = '{0}/condition/{1}' -f $resourcePath, $ID

    $requestBody | Invoke-BBServerRestMethod -Connection $Connection -Method Put -ApiName 'default-reviewers' -ResourcePath $resourcePath
}
