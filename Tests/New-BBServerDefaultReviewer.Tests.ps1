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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$projectKey = 'NBBSDR'
$projectName = 'New-BBServerDefaultReviewer Tests'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName $projectName
$output = $null
$repoName = $null

function Init
{
    $script:output = $null

    Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey |
        Select-Object -ExpandProperty 'Name' |
        Remove-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Force

    Remove-BBServerTestProject -Connection $bbConnection -Key $projectKey -Force
    New-BBServerTestProject -Connection $bbConnection -Key $projectKey -Name $projectName

    $testUsers = Get-BBServerUser -Connection $bbConnection | Where-Object { $_.name -ne 'admin' }
    foreach ($user in $testUsers)
    {
        Invoke-BBServerRestMethod -Connection $BBConnection -Method Delete -ApiName 'api' -ResourcePath ('admin/users?name={0}' -f $user.name)
    }

    $repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    $repo | Initialize-TestRepository -Connection $bbConnection | Out-Null
}

function GivenUser
{
    param(
        [string[]]
        $Username
    )

    foreach($user in $Username)
    {
        if ($user -eq 'admin')
        {
            # 'admin' already exists from the local Bitbucket server setup in .\init.ps1
            continue
        }

        $requestQueryParameters = 'name={0}&password=hunter2&displayName={0}&emailAddress={0}@example.com' -f $user
        $requestQueryParameters = [Uri]::EscapeUriString($requestQueryParameters)

        Invoke-BBServerRestMethod -Connection $BBConnection -Method Post -ApiName 'api' -ResourcePath ('admin/users?{0}' -f $requestQueryParameters)
    }
}

function ThenApprovalCount
{
    param(
        $ExpectedCount
    )

    $output.requiredApprovals | Should -Be $ExpectedCount
}

function ThenDefaultReviewerConditionCount
{
    param(
        [switch]
        $ForProject,

        [switch]
        $ForRepository,

        [int]
        $Is
    )

    $conditionScope = 'PROJECT'
    $repositoryParam = @{ }
    if ($ForRepository)
    {
        $repositoryParam = @{ 'RepositoryName' = $repoName }
        $conditionScope = 'REPOSITORY'
    }

    $defaultReviewerConditions = Get-BBServerDefaultReviewer -Connection $bbConnection -ProjectKey $projectKey @repositoryParam

    if ($Is -eq 0)
    {
        $defaultReviewerConditions | Should -BeNullOrEmpty
    }
    else
    {
        $defaultReviewerConditions | Where-Object { $_.scope.type -eq $conditionScope } | Should -HaveCount $Is
    }
}

function ThenErrorMatches
{
    param(
        $ExpectedError
    )

    $Global:Error | Should -Match $ExpectedError
}

function ThenNoErrors
{
    $Global:Error | Should -BeNullOrEmpty
}

function ThenNoOutput
{
    $output | Should -BeNullOrEmpty
}

function ThenScoped
{
    [CmdletBinding(DefaultParameterSetName='ForProject')]
    param(
        [Parameter(ParameterSetName='ForProject')]
        [switch]
        $ForProject,
        [Parameter(ParameterSetName='ForRepository')]
        [switch]
        $ForRepository
    )

    $expectedScope = 'PROJECT'
    if ($ForRepository)
    {
        $expectedScope = 'REPOSITORY'
    }

    $output.scope.type | Should -BeExactly $expectedScope
}

function ThenSourceBranchMatcher
{
    param(
        [ValidateSet('ANY_REF', 'BRANCH', 'PATTERN', 'MODEL_CATEGORY', 'MODEL_BRANCH')]
        [string]
        $Type,

        [string]
        $Value
    )

    if ($Type -eq 'ANY_REF')
    {
        $Value = 'ANY_REF_MATCHER_ID'
    }

    $output.sourceRefMatcher.type.id | Should -BeExactly $Type
    $output.sourceRefMatcher.id | Should -BeExactly $Value
}

function ThenTargetBranchMatcher
{
    param(
        [ValidateSet('ANY_REF', 'BRANCH', 'PATTERN', 'MODEL_CATEGORY', 'MODEL_BRANCH')]
        [string]
        $Type,

        [string]
        $Value
    )

    if ($Type -eq 'ANY_REF')
    {
        $Value = 'ANY_REF_MATCHER_ID'
    }

    $output.targetRefMatcher.type.id | Should -BeExactly $Type
    $output.targetRefMatcher.id | Should -BeExactly $Value
}

function ThenUser
{
    param(
        $ExpectedUsernames
    )

    $output.reviewers | Should -HaveCount ($ExpectedUsernames | Measure-Object).Count

    foreach ($username in $ExpectedUsernames)
    {
        $output.reviewers.name | Should -Contain $username
    }
}

function WhenCreatingDefaultReviewer
{
    [CmdletBinding(DefaultParameterSetName='Project')]
    param(
        [Parameter(Mandatory, ParameterSetName='Project')]
        [switch]
        $ForProject,

        [Parameter(Mandatory, ParameterSetName='Repository')]
        [switch]
        $ForRepository,

        [Parameter(Mandatory)]
        [object[]]
        $User,

        [Parameter(Mandatory)]
        [int]
        $ApprovalCount,

        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        $SourceBranchType,

        [string]
        $SourceBranchValue,

        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        $TargetBranchType,

        [string]
        $TargetBranchValue
    )

    $optionalParams = @{}
    if ($ForRepository)
    {
        $optionalParams['RepositoryName'] = $repoName
    }

    if ($SourceBranchType)
    {
        $optionalParams['SourceBranchType'] = $SourceBranchType
    }

    if ($SourceBranchValue)
    {
        $optionalParams['SourceBranchValue'] = $SourceBranchValue
    }

    if ($TargetBranchType)
    {
        $optionalParams['TargetBranchType'] = $TargetBranchType
    }

    if ($TargetBranchValue)
    {
        $optionalParams['TargetBranchValue'] = $TargetBranchValue
    }

    $Global:Error.Clear()


    $mandatoryParams = @{
        Connection    = $bbConnection
        ProjectKey    = $projectKey
        User          = $User
        ApprovalCount = $ApprovalCount
    }

    $script:output = New-BBServerDefaultReviewer @mandatoryParams @optionalParams
}

Describe 'New-BBServerDefaultReviewer.when given minimal parameters' {
    It 'should create default reviewers' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 1

        ThenDefaultReviewerConditionCount -ForProject -Is 1
        ThenScoped -ForProject
        ThenUser 'admin'
        ThenApprovalCount 1
        ThenSourceBranchMatcher -Type 'ANY_REF'
        ThenTargetBranchMatcher -Type 'ANY_REF'
        ThenNoErrors

        Context 'creating a new default reviewer condition with the same properties' {
            WhenCreatingDefaultReviewer -ForProject `
                                        -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                        -ApprovalCount 1

            ThenDefaultReviewerConditionCount -ForProject -Is 2
            ThenNoErrors
        }

        Context 'creating a new default reviewer condition at repository level' {
            WhenCreatingDefaultReviewer -ForRepository `
                                        -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                        -ApprovalCount 1 `
                                        -SourceBranchType 'Name' `
                                        -SourceBranchValue 'develop' `
                                        -TargetBranchType 'Name' `
                                        -TargetBranchValue 'master'

            ThenDefaultReviewerConditionCount -ForProject -Is 2
            ThenDefaultReviewerConditionCount -ForRepository -Is 1
            ThenScoped -ForRepository
            ThenUser 'admin'
            ThenApprovalCount 1
            ThenSourceBranchMatcher -Type 'BRANCH' -Value 'develop'
            ThenTargetBranchMatcher -Type 'BRANCH' -Value 'master'
            ThenNoErrors
        }
    }
}

Describe 'New-BBServerDefaultReviewer.when given multiple users' {
    It 'should create on rule with multiple reviewers' {
        Init
        GivenUser 'admin', 'thing1', 'thing2'
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection) `
                                    -ApprovalCount 0 `
                                    -SourceBranchType 'Any' `
                                    -TargetBranchType 'Any'

        ThenDefaultReviewerConditionCount -ForProject -Is 1
        ThenUser 'admin', 'thing1', 'thing2'
        ThenApprovalCount 0
        ThenNoErrors
    }
}

Describe 'New-BBServerDefaultReviewer.when given user names instead of user objects' {
    It 'should fail' {
        Init
        GivenUser 'admin', 'thing1', 'thing2'
        WhenCreatingDefaultReviewer -ForProject `
                                    -User 'admin', 'thing1', 'thing2' `
                                    -ApprovalCount 0 `
                                    -SourceBranchType 'Any' `
                                    -TargetBranchType 'Any' `
                                    -ErrorAction SilentlyContinue

        ThenDefaultReviewerConditionCount -ForProject -Is 0
        ThenNoOutput
        ThenErrorMatches 'doesn''t have a ".+" property. Make sure you''re using the "Get-BBServerUser"'
    }
}

Describe 'New-BBServerDefaultReviewer.when given approval count is greater than number of given users' {
    It 'should fail' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 2 `
                                    -ErrorAction SilentlyContinue

        ThenDefaultReviewerConditionCount -ForProject -Is 0
        ThenNoOutput
        ThenErrorMatches 'must be less than or equal to'
    }
}

Describe 'New-BBServerDefaultReviewer.when given source type Branch but no name value' {
    It 'should fail' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 1 `
                                    -SourceBranchType 'Name' `
                                    -ErrorAction SilentlyContinue

        ThenDefaultReviewerConditionCount -ForProject -Is 0
        ThenNoOutput
        ThenErrorMatches '"SourceBranchValue" cannot be empty'
    }
}

Describe 'New-BBServerDefaultReviewer.when given target type Branch but no name value' {
    It 'should fail' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 1 `
                                    -TargetBranchType 'Name' `
                                    -ErrorAction SilentlyContinue

        ThenDefaultReviewerConditionCount -ForProject -Is 0
        ThenNoOutput
        ThenErrorMatches '"TargetBranchValue" cannot be empty'
    }
}

Describe 'New-BBServerDefaultReviewer.when given source type Pattern but no pattern value' {
    It 'should fail' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 1 `
                                    -SourceBranchType 'Pattern' `
                                    -ErrorAction SilentlyContinue

        ThenDefaultReviewerConditionCount -ForProject -Is 0
        ThenNoOutput
        ThenErrorMatches '"SourceBranchValue" cannot be empty'
    }
}

Describe 'New-BBServerDefaultReviewer.when given target type Pattern but no pattern value' {
    It 'should fail' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 1 `
                                    -TargetBranchType 'Pattern' `
                                    -ErrorAction SilentlyContinue

        ThenDefaultReviewerConditionCount -ForProject -Is 0
        ThenNoOutput
        ThenErrorMatches '"TargetBranchValue" cannot be empty'
    }
}

Describe 'New-BBServerDefaultReviewer.when given branch name' {
    It 'should create reviewers matching those branches' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 0 `
                                    -SourceBranchType 'Name' `
                                    -SourceBranchValue 'develop' `
                                    -TargetBranchType 'Name' `
                                    -TargetBranchValue 'master'

        ThenDefaultReviewerConditionCount -ForProject -Is 1
        ThenScoped -ForProject
        ThenSourceBranchMatcher -Type 'BRANCH' -Value 'develop'
        ThenTargetBranchMatcher -Type 'BRANCH' -Value 'master'
        ThenNoErrors
    }
}

Describe 'New-BBServerDefaultReviewer.when given branch pattern' {
    It 'should create reviewers matching branch patterns' {
        Init
        WhenCreatingDefaultReviewer -ForProject `
                                    -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                    -ApprovalCount 1 `
                                    -TargetBranchType 'Pattern' `
                                    -TargetBranchValue 'hotfix/*'

        ThenDefaultReviewerConditionCount -ForProject -Is 1
        ThenScoped -ForProject
        ThenSourceBranchMatcher -Type 'ANY_REF'
        ThenTargetBranchMatcher -Type 'PATTERN' -Value 'hotfix/*'
        ThenNoErrors
    }
}

foreach ($category in @('Feature', 'Bugfix', 'Hotfix', 'Release'))
{
    Describe ('New-BBServerDefaultReviewer.when given branch model category "{0}"' -f $category) {
        It 'should create reviwers' {
            Init
            WhenCreatingDefaultReviewer -ForProject `
                                        -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                        -ApprovalCount 1 `
                                        -TargetBranchType 'Model' `
                                        -TargetBranchValue $category

            ThenDefaultReviewerConditionCount -ForProject -Is 1
            ThenSourceBranchMatcher -Type 'ANY_REF'
            ThenTargetBranchMatcher -Type 'MODEL_CATEGORY' -Value $category.ToUpperInvariant()
            ThenNoErrors
        }
    }
}

foreach ($branch in @('Production', 'Development'))
{
    Describe ('New-BBServerDefaultReviewer.when given branch model branch "{0}"' -f $branch) {
        It 'should create reviwers' {
            Init
            WhenCreatingDefaultReviewer -ForProject `
                                        -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                        -ApprovalCount 1 `
                                        -TargetBranchType 'Model' `
                                        -TargetBranchValue $branch

            ThenDefaultReviewerConditionCount -ForProject -Is 1
            ThenSourceBranchMatcher -Type 'ANY_REF'
            ThenTargetBranchMatcher -Type 'MODEL_BRANCH' -Value $branch.ToLowerInvariant()
            ThenNoErrors
        }
    }

    Describe 'New-BBServerDefaultReviewer.when given invalid branch model value' {
        It 'should fail' {
            Init
            WhenCreatingDefaultReviewer -ForProject `
                                        -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                        -ApprovalCount 1 `
                                        -TargetBranchType 'Model' `
                                        -TargetBranchValue 'InvalidBranchModelName' `
                                        -ErrorAction SilentlyContinue

            ThenDefaultReviewerConditionCount -ForProject -Is 0
            ThenNoOutput
            ThenErrorMatches 'must be one of "Feature, Bugfix, Hotfix, Release, Development, Production"'
        }
    }

    Describe 'New-BBServerDefaultReviewer.when creating condition at repository level' {
        It 'should succeed' {
            Init
            WhenCreatingDefaultReviewer -ForRepository `
                                        -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                        -ApprovalCount 1

            ThenDefaultReviewerConditionCount -ForProject -Is 0
            ThenDefaultReviewerConditionCount -ForRepository -Is 1
            ThenScoped -ForRepository
            ThenUser 'admin'
            ThenApprovalCount 1
            ThenSourceBranchMatcher -Type 'ANY_REF'
            ThenTargetBranchMatcher -Type 'ANY_REF'
            ThenNoErrors
        }
    }
}
