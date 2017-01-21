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

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)
& (Join-Path -Path $PSScriptRoot -ChildPath '..\LibGit2\Import-LibGit2.ps1' -Resolve)

$conn = New-BBServerTestConnection -ProjectKey 'SBBSCBS' -ProjectName 'Set-BBServerCommitBuildStatus'

function Assert-StatusUpdatedTo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateSet('InProgress','Successful','Failed')]
        $ExpectedStatus,

        [hashtable]
        $FromEnvironment
    )

    It 'should post status to Bitbucker Server' {

        $info = Get-BBServerCommitBuildStatus -Connection $conn -CommitID $FromEnvironment.CommitID
        $info | Should Not BeNullOrEmpty
        $info.state | Should Be $ExpectedStatus
        $info.key | Should Be $FromEnvironment.Key
        $info.name | Should Be $FromEnvironment.Name
        $info.url | Should Be $FromEnvironment.BuildUri
        $info.dateAdded | Should BeOfType ([datetime])
        if( $FromEnvironment.Description )
        {
            $info.description | Should Be $FromEnvironment.Description
        }
        else
        {
            $info.description | Should BeNullOrEmpty
        }
    }
}

function New-BuildEnvironment
{
    param(
        [Switch]
        $ForJenkins,

        [string]
        $GivenDescription
    )

    New-GitRepository -Path $TestDrive.FullName | Out-Null
    Push-Location -Path $TestDrive.FullName
    $commit = $null
    try
    {
        '' | Set-Content 'file'

        Add-GitItem -Path 'file'

        $commit = Save-GitChange -Message 'Creating initial commit.'

    }
    finally
    {
        Pop-Location
    }

    $buildEnv = @{
                    CommitID = $commit.Id.Sha;
                    Key = 'my_build_tag';
                    BuildUri = 'https://example.com/my_build_tag';
                    Name = 'my_build';
                    Description = $GivenDescription;
                 }

    if( $ForJenkins )
    {
        Mock -CommandName 'Test-Path' -ModuleName 'BitbucketServerAutomation' -MockWith { $true } -ParameterFilter { $Path -eq 'env:JENKINS_URL' }
        Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.CommitID } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:GIT_COMMIT' }
        Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.Key } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:BUILD_TAG' }
        Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.BuildUri } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:BUILD_URL' }
        Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.Name } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:JOB_NAME' }
    }

    return $buildEnv
}

Describe 'Set-BBServerCommitBuildStatus.when a build starts under Jenkins' {
    $buildEnv = New-BuildEnvironment -ForJenkins

    Set-BBServerCommitBuildStatus -Connection $conn -Status InProgress 

    Assert-StatusUpdatedTo InProgress -FromEnvironment $buildEnv
}

Describe 'Set-BBServerCommitBuildStatus.when called from an unsupported build server' {
    $buildEnv = New-BuildEnvironment -GivenDescription 'fubarsnafu'
    Set-BBServerCommitBuildStatus -Connection $conn -Status Successful @buildEnv
    Assert-StatusUpdatedTo Successful -FromEnvironment $buildEnv
}