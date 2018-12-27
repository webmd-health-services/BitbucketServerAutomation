
# Copyright 2016 - 2018 WebMD Health Services
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

$projectKey = 'GBBSDR'
$projectName = 'Get-BBServerDefaultReviewer Tests'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName $projectName
$repo = $null
$repoName = $null
$repoRoot = $null
$output = $null

function Init
{
    $script:output = $null

    Remove-BBServerTestProject -Connection $bbConnection -Key $projectKey -Force
    New-BBServerTestProject -Connection $bbConnection -Key $projectKey -Name $projectName

    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'
}

function GivenDefaultReviewerConfig
{
    [CmdletBinding(DefaultParameterSetName='Project')]
    param(
        [Parameter(Mandatory, ParameterSetName='Project')]
        [switch]
        $ForProject,

        [Parameter(Mandatory, ParameterSetName='Repository')]
        [switch]
        $ForRepository
    )

    $resourcePath = 'projects/{0}/condition' -f $projectKey
    if ($ForRepository)
    {
        $resourcePath = 'projects/{0}/repos/{1}/condition' -f $projectKey, $repoName
    }

    $apiName = 'default-reviewers'

    $requestBody = @{
        reviewers = @(
            & {
                Get-BBServerUser -Connection $bbConnection -Filter 'admin' |
                Select-Object -Property 'name', 'emailAddress', 'id', 'displayName', 'active', 'slug', 'type'
            }
        )
        sourceMatcher = @{
            active = 'true'
            id = 'ANY_REF_MATCHER_ID'
            displayId = 'ANY_REF_MATCHER_ID'
            type = @{
                id = 'ANY_REF'
                name = 'Any branch'
            }
        }
        targetMatcher = @{
            active = 'true'
            id = 'ANY_REF_MATCHER_ID'
            displayId = 'ANY_REF_MATCHER_ID'
            type = @{
                id = 'ANY_REF'
                name = 'Any branch'
            }
        }
        requiredApprovals = 1
    }

    $requestBody | Invoke-BBServerRestMethod -Connection $bbConnection -Method Post -ApiName $apiName -ResourcePath $resourcePath
}

function ThenDefaultReviewerScope
{
    param(
        [int]
        $ForProject = 0,

        [int]
        $ForRepository = 0
    )

    It 'should return default reviewers for the correct scope' {
        $output | Should -Not -BeNullOrEmpty

        $output | Where-Object { $_.scope.type -eq 'PROJECT' } | Should -HaveCount $ForProject

        $output | Where-Object { $_.scope.type -eq 'REPOSITORY' } | Should -HaveCount $ForRepository
    }
}

function ThenNoErrors
{
    It 'should not write any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenOutputCount
{
    param(
        $ExpectedCount
    )

    It 'should return the correct number of objects' {
        $output | Should -HaveCount $ExpectedCount
    }
}

function ThenReturnedDefaultReviewerInfo
{
    $expectedProperties = @('id', 'scope', 'sourceRefMatcher', 'targetRefMatcher', 'reviewers', 'requiredApprovals')

    It 'should return the default reviewer objects as-is from the api endpoint' {
        $output | Should -Not -BeNullOrEmpty

        foreach ($object in $output)
        {
            foreach ($property in $expectedProperties)
            {
                $object | Get-Member -Name $property | Should -Not -BeNullOrEmpty
            }
        }
    }
}

function ThenReturnedNothing
{
    It 'should not return anything' {
        $output | Should -BeNullOrEmpty
    }
}

function WhenGettingDefaultReviewers
{
    [CmdletBinding(DefaultParameterSetName='Project')]
    param(
        [Parameter(Mandatory, ParameterSetName='Project')]
        [switch]
        $ForProject,

        [Parameter(Mandatory, ParameterSetName='Repository')]
        [switch]
        $ForRepository
    )

    $repositoryParam = @{}
    if ($ForRepository)
    {
        $repositoryParam['RepositoryName'] = $repoName
    }

    $Global:Error.Clear()

    $script:output = Get-BBServerDefaultReviewer -Connection $bbConnection -ProjectKey $projectKey @repositoryParam
}

Describe 'Get-BBServerDefaultReviewer.when there are no default reviewers' {
    Init
    WhenGettingDefaultReviewers -ForRepository
    ThenReturnedNothing
    ThenNoErrors
}

Describe 'Get-BBServerDefaultReviewer.when getting for project scope' {
    Init
    GivenDefaultReviewerConfig -ForProject
    GivenDefaultReviewerConfig -ForRepository
    WhenGettingDefaultReviewers -ForProject
    ThenOutputCount 1
    ThenDefaultReviewerScope -ForProject 1 -ForRepository 0
    ThenReturnedDefaultReviewerInfo
    ThenNoErrors
}

Describe 'Get-BBServerDefaultReviewer.when multiple default reviewer configs exist' {
    Init
    1..4 | ForEach-Object { GivenDefaultReviewerConfig -ForProject }
    WhenGettingDefaultReviewers -ForProject
    ThenOutputCount 4
    ThenDefaultReviewerScope -ForProject 4 -ForRepository 0
    ThenReturnedDefaultReviewerInfo
    ThenNoErrors
}

Describe 'Get-BBServerDefaultReviewer.when getting for repository scope' {
    Init
    1..2 | ForEach-Object { GivenDefaultReviewerConfig -ForProject }
    1..4 | ForEach-Object { GivenDefaultReviewerConfig -ForRepository }
    WhenGettingDefaultReviewers -ForRepository
    ThenOutputCount 6
    ThenDefaultReviewerScope -ForProject 2 -ForRepository 4
    ThenReturnedDefaultReviewerInfo
    ThenNoErrors
}

Describe 'Get-BBServerDefaultReviewer.when getting for repository scope but only project level default reviewers exist' {
    Init
    1..2 | ForEach-Object { GivenDefaultReviewerConfig -ForProject }
    WhenGettingDefaultReviewers -ForRepository
    ThenOutputCount 2
    ThenDefaultReviewerScope -ForProject 2 -ForRepository 0
    ThenReturnedDefaultReviewerInfo
    ThenNoErrors
}
