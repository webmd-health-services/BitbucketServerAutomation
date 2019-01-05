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

$projectKey = 'SBBSDR'
$projectName = 'Set-BBServerDefaultReviewer Tests'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName $projectName
$output = $null
$repoName = $null

function Init
{
    $script:output = $null

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

function GivenDefaultReviewer
{
    param(
        [switch]
        $ForProject,

        [switch]
        $ForRepository,

        [object[]]
        $User,

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

    if (-not $User)
    {
        $User = Get-BBServerUser -Connection $bbConnection -Filter 'admin'
    }

    $optionalParams = @{ }
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

    New-BBServerDefaultReviewer -Connection $bbConnection -ProjectKey $projectKey -User $User -ApprovalCount $ApprovalCount @optionalParams
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

    It 'should set the approval count' {
        $output.requiredApprovals | Should -Be $ExpectedCount
    }
}

function ThenErrorMatches
{
    param(
        $ExpectedError
    )

    It ('should write an error matching /{0}/' -f $ExpectedError) {
        $Global:Error | Should -Match $ExpectedError
    }
}

function ThenNoErrors
{
    It 'should not write any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenNoOutput
{
    It 'should not return anything' {
        $output | Should -BeNullOrEmpty
    }
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

    It 'should set the condition at the correct scope' {
        $output.scope.type | Should -BeExactly $expectedScope
    }
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

    It 'should set the source branch matching properties' {
        $output.sourceRefMatcher.type.id | Should -BeExactly $Type
        $output.sourceRefMatcher.id | Should -BeExactly $Value
    }
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

    It 'should set the target branch matching properties' {
        $output.targetRefMatcher.type.id | Should -BeExactly $Type
        $output.targetRefMatcher.id | Should -BeExactly $Value
    }
}

function ThenUnchanged
{
    param(
        [object]
        $existingCondition,

        [switch]
        $Scope,

        [switch]
        $ApprovalCount,

        [switch]
        $SourceBranch,

        [switch]
        $TargetBranch,

        [switch]
        $User
    )

    $currentCondition =
        Get-BBServerDefaultReviewer -Connection $bbConnection -ProjectKey $projectKey -RepositoryName $repoName |
        Where-Object { $_.id -eq $existingCondition.id }

    if ($Scope)
    {
        It 'should not change the existing scope' {
            $currentCondition.scope.type | Should -BeExactly $existingCondition.scope.type
        }
    }

    if ($ApprovalCount)
    {
        It 'should not change the existing approval count' {
            $currentCondition.requiredApprovals | Should -Be $existingCondition.requiredApprovals
        }
    }

    if ($SourceBranch)
    {
        It 'should not change the existing source branch matching properties' {
            $currentCondition.sourceRefMatcher.type.id | Should -BeExactly $existingCondition.sourceRefMatcher.type.id
            $currentCondition.sourceRefMatcher.id | Should -BeExactly $existingCondition.sourceRefMatcher.id
        }
    }

    if ($TargetBranch)
    {
        It 'should not change the existing target branch matching properties' {
            $currentCondition.targetRefMatcher.type.id | Should -BeExactly $existingCondition.targetRefMatcher.type.id
            $currentCondition.targetRefMatcher.id | Should -BeExactly $existingCondition.targetRefMatcher.id
        }
    }

    if ($User)
    {
        It 'should not change the existing users' {
            $currentCondition.reviewers | Should -HaveCount ($existingCondition.reviewers | Measure-Object).Count

            foreach ($username in $existingCondition.reviewers.name)
            {
                $currentCondition.reviewers.name | Should -Contain $username
            }
        }
    }
}

function ThenUser
{
    param(
        $ExpectedUsernames
    )

    It 'should add the expected users to the condition' {
        $output.reviewers | Should -HaveCount ($ExpectedUsernames | Measure-Object).Count

        foreach ($username in $ExpectedUsernames)
        {
            $output.reviewers.name | Should -Contain $username
        }
    }
}

function WhenSettingDefaultReviewer
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
        [int]
        $ID,

        [object[]]
        $User,

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

    if ($User)
    {
        $optionalParams['User'] = $User
    }

    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('ApprovalCount'))
    {
        $optionalParams['ApprovalCount'] = $ApprovalCount
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
        Connection = $bbConnection
        ProjectKey = $projectKey
        ID         = $ID
    }

    $script:output = Set-BBServerDefaultReviewer @mandatoryParams @optionalParams
}

Describe 'Set-BBServerDefaultReviewer.when given invalid ID' {
    Init
    WhenSettingDefaultReviewer -ForProject -ID 999 -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenErrorMatches 'with ID "999" does not exist'
}

Describe 'Set-BBServerDefaultReviewer.when updating a Project level condition from a Repository scope' {
    Init
    $existing = GivenDefaultReviewer -ForProject -ApprovalCount 1
    WhenSettingDefaultReviewer -ForRepository -ID $existing.id  -ApprovalCount 0
    ThenApprovalCount 0
    ThenUnchanged $existing -Scope -SourceBranch -TargetBranch -User
    ThenNoErrors
}

Describe 'Set-BBServerDefaultReviewer.when updating a Repository level condition' {
    Init
    GivenUser 'admin', 'thing1', 'thing2'
    $existing = GivenDefaultReviewer -ForRepository `
                                     -SourceBranchType 'Name' `
                                     -SourceBranchValue 'develop' `
                                     -ApprovalCount 1

    WhenSettingDefaultReviewer -ForRepository `
                               -ID $existing.id `
                               -User (Get-BBServerUser -Connection $bbConnection) `
                               -SourceBranchType 'Any' `
                               -TargetBranchType 'Name' `
                               -TargetBranchValue 'master'

    ThenScoped -ForRepository
    ThenUser 'admin', 'thing1', 'thing2'
    ThenSourceBranchMatcher -Type 'ANY_REF'
    ThenTargetBranchMatcher -Type 'BRANCH' -Value 'master'
    ThenUnchanged $existing -ApprovalCount
    ThenNoErrors
}

Describe 'Set-BBServerDefaultReviewer.when given user names instead of user objects' {
    Init
    GivenUser 'admin', 'thing1', 'thing2'
    $existing = GivenDefaultReviewer -ForProject -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin')
    WhenSettingDefaultReviewer -ForProject `
                               -ID $existing.id `
                               -User 'thing1', 'thing2' `
                               -ErrorAction SilentlyContinue

    ThenNoOutput
    ThenErrorMatches 'does not have the expected properties\. Use "Get-BBServerUser"'
}

Describe 'Set-BBServerDefaultReviewer.when approval count is greater than count of existing users' {
    Init
    $existing = GivenDefaultReviewer -ForProject `
                                     -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                     -ApprovalCount 1

    WhenSettingDefaultReviewer -ForProject -ID $existing.id -ApprovalCount 2 -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount
    ThenErrorMatches 'must be less than or equal to'
}

Describe 'Set-BBServerDefaultReviewer.when approval count is greater than count of given users' {
    Init
    GivenUser 'admin', 'thing1', 'thing2'
    $existing = GivenDefaultReviewer -ForProject `
                                     -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin') `
                                     -ApprovalCount 1

    WhenSettingDefaultReviewer -ForProject `
                               -ID $existing.id `
                               -User (Get-BBServerUser -Connection $bbConnection -Filter 'thing') `
                               -ApprovalCount 5 `
                               -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount -User
    ThenErrorMatches 'must be less than or equal to'
}

Describe 'Set-BBServerDefaultReviewer.when updating users' {
    Init
    GivenUser 'admin', 'thing1', 'thing2'
    $existing = GivenDefaultReviewer -ForProject -User (Get-BBServerUser -Connection $bbConnection -Filter 'admin')
    WhenSettingDefaultReviewer -ForProject -ID $existing.id -User (Get-BBServerUser -Connection $bbConnection)
    ThenUser 'admin', 'thing1', 'thing2'
    ThenUnchanged $existing -Scope -ApprovalCount -SourceBranch -TargetBranch
    ThenNoErrors
}

Describe 'Set-BBServerDefaultReviewer.when updating approval count' {
    Init
    $existing = GivenDefaultReviewer -ForProject -ApprovalCount 1
    WhenSettingDefaultReviewer -ForProject -ID $existing.id -ApprovalCount 0
    ThenApprovalCount 0
    ThenUnchanged $existing -Scope -SourceBranch -TargetBranch -User
    ThenNoErrors
}

Describe 'Set-BBServerDefaultReviewer.when updating source branch to Any and target branch to Name' {
    Init
    $existing = GivenDefaultReviewer -ForProject -SourceBranchType 'Name' -SourceBranchValue 'develop'
    WhenSettingDefaultReviewer -ForProject `
                               -ID $existing.id `
                               -SourceBranchType 'Any' `
                               -TargetBranchType 'Name' `
                               -TargetBranchValue 'master'

    ThenSourceBranchMatcher -Type 'ANY_REF'
    ThenTargetBranchMatcher -Type 'BRANCH' -Value 'master'
    ThenUnchanged $existing -Scope -ApprovalCount -User
    ThenNoErrors
}

Describe 'Set-BBServerDefaultReviewer.when updating source branch to Pattern and target branch to Name' {
    Init
    $existing = GivenDefaultReviewer -ForProject -SourceBranchType 'Name' -SourceBranchValue 'develop'
    WhenSettingDefaultReviewer -ForProject `
                               -ID $existing.id `
                               -SourceBranchType 'Pattern' `
                               -SourceBranchValue 'hotfix/*' `
                               -TargetBranchType 'Name' `
                               -TargetBranchValue 'master'

    ThenSourceBranchMatcher -Type 'PATTERN' -Value 'hotfix/*'
    ThenTargetBranchMatcher -Type 'BRANCH' -Value 'master'
    ThenUnchanged $existing -Scope -ApprovalCount -User
    ThenNoErrors
}

foreach ($category in @('Feature', 'Bugfix', 'Hotfix', 'Release'))
{
    Describe ('Set-BBServerDefaultReviewer.when updating branch to Model Category "{0}"' -f $category) {
        Init
        $existing = GivenDefaultReviewer -ForProject -SourceBranchType 'Name' -SourceBranchValue 'develop'
        WhenSettingDefaultReviewer -ForProject `
                                -ID $existing.id `
                                -SourceBranchType 'Any' `
                                -TargetBranchType 'Model' `
                                -TargetBranchValue $category

        ThenSourceBranchMatcher -Type 'ANY_REF'
        ThenTargetBranchMatcher -Type 'MODEL_CATEGORY' -Value $category.ToUpperInvariant()
        ThenUnchanged $existing -Scope -ApprovalCount -User
        ThenNoErrors
    }
}

foreach ($branch in @('Production', 'Development'))
{
    Describe ('Set-BBServerDefaultReviewer.when updating branch to Model Branch "{0}"' -f $branch) {
        Init
        $existing = GivenDefaultReviewer -ForProject -SourceBranchType 'Name' -SourceBranchValue 'develop'
        WhenSettingDefaultReviewer -ForProject `
                                -ID $existing.id `
                                -SourceBranchType 'Any' `
                                -TargetBranchType 'Model' `
                                -TargetBranchValue $branch

        ThenSourceBranchMatcher -Type 'ANY_REF'
        ThenTargetBranchMatcher -Type 'MODEL_BRANCH' -Value $branch.ToLowerInvariant()
        ThenUnchanged $existing -Scope -ApprovalCount -User
        ThenNoErrors
    }
}

Describe 'Set-BBServerDefaultReviewer.when given source branch value but no type' {
    Init
    $existing = GivenDefaultReviewer -ForProject
    WhenSettingDefaultReviewer -ForProject -ID $existing.id -SourceBranchValue 'hotfix/*' -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount -SourceBranch -TargetBranch -User
    ThenErrorMatches 'must specify a "SourceBranchType" when giving a "SourceBranchValue"'
}

Describe 'Set-BBServerDefaultReviewer.when given target branch value but no type' {
    Init
    $existing = GivenDefaultReviewer -ForProject
    WhenSettingDefaultReviewer -ForProject -ID $existing.id -TargetBranchValue 'hotfix/*' -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount -SourceBranch -TargetBranch -User
    ThenErrorMatches 'must specify a "TargetBranchType" when giving a "TargetBranchValue"'
}

Describe 'Set-BBServerDefaultReviewer.when given invalid value for Model branch type' {
    Init
    $existing = GivenDefaultReviewer -ForProject
    WhenSettingDefaultReviewer -ForProject -ID $existing.id ` -TargetBranchType 'Model' ` -TargetBranchValue 'custom' -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount -SourceBranch -TargetBranch -User
    ThenErrorMatches 'must be one of "Feature, Bugfix, Hotfix, Release, Development, Production"'
}

Describe 'Set-BBServerDefaultReviewer.when source branch Type other than "Any" but no Value' {
    Init
    $existing = GivenDefaultReviewer -ForProject
    WhenSettingDefaultReviewer -ForProject -ID $existing.id -SourceBranchType 'Name' -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount -SourceBranch -TargetBranch -User
    ThenErrorMatches '"SourceBranchValue" cannot be empty'
}

Describe 'Set-BBServerDefaultReviewer.when target branch Type other than "Any" but no Value' {
    Init
    $existing = GivenDefaultReviewer -ForProject
    WhenSettingDefaultReviewer -ForProject -ID $existing.id -TargetBranchType 'Name' -ErrorAction SilentlyContinue
    ThenNoOutput
    ThenUnchanged $existing -ApprovalCount -SourceBranch -TargetBranch -User
    ThenErrorMatches '"TargetBranchValue" cannot be empty'
}
