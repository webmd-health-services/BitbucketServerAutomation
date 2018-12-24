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
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'GBBSFILE'
$repo = $null
$repoName = $null 
$repoRoot = $null
[string[]]$getFiles = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerFile Tests'

$initialFileList = (
                    'TestFileA.txt',
                    'TestFileB.txt',
                    'FileTest1.doc',
                    'FileTest2.doc',
                    'TestFolderA/TestFileA.txt',
                    'TestFolderA/FileTest1.doc',
                    'TestFolderA/TestFolderB/TestFileB.txt',
                    'TestFolderA/TestFolderB/FileTest2.doc'
                   )

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection -NoInitialCommit
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenARepositoryWithFiles
{
    New-TestRepoCommit -RepoRoot $repoRoot -Filename $initialFileList -Connection $bbConnection
}

function WhenGettingFiles
{
    [CmdletBinding()]
    param(
        [string]
        $WithSearchFilter,

        [string]
        $WithPath
    )

    $Global:Error.Clear()

    $bbServerFileParams = @{}
    if( $WithSearchFilter )
    {
        $bbServerFileParams['Filter'] = $WithSearchFilter
    }
    
    if( $WithPath )
    {
        $bbServerFileParams['Path'] = $WithPath
    }
    
    $result = Get-BBServerFile -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName @bbServerFileParams -ErrorAction SilentlyContinue
    if( -not $result )
    {
        $result = @()
    }
    $script:getFiles = $result
}

function ThenItShouldReturn
{
    param(
        [string[]]
        $ExpectedPath
    )

    It ('should retrieve exactly {0} file(s)' -f $ExpectedPath.Count) {
        $getFiles.Count | Should Be $ExpectedPath.Count
    }

    $ExpectedPath | ForEach-Object {
        It ('should return {0}' -f $_) {
            $getFiles -contains $_ | Should Be True
        }
    }
}

Describe 'Get-BBServerFile.when returning all files' {
    Init
    GivenARepositoryWithFiles @(
                                'TestFileA.txt',
                                'TestFileB.txt',
                                'FileTest1.doc',
                                'FileTest2.doc',
                                'TestFolderA/TestFileA.txt',
                                'TestFolderA/FileTest1.doc',
                                'TestFolderA/TestFolderB/TestFileB.txt',
                                'TestFolderA/TestFolderB/FileTest2.doc'
                               )
    WhenGettingFiles
    ThenItShouldReturn @(
                            'TestFileA.txt',
                            'TestFileB.txt',
                            'FileTest1.doc',
                            'FileTest2.doc',
                            'TestFolderA/TestFileA.txt',
                            'TestFolderA/FileTest1.doc',
                            'TestFolderA/TestFolderB/TestFileB.txt',
                            'TestFolderA/TestFolderB/FileTest2.doc'
                        )
}

Describe 'Get-BBServerFile.when returning files from the root named ''FileTest1.doc''' {
    Init
    GivenARepositoryWithFiles @(
                                'FileTest1.doc',
                                'TestFolderA/FileTest1.doc'
                               )
    WhenGettingFiles -WithSearchFilter 'FileTest1.doc'
    ThenItShouldReturn 'FileTest1.doc'
}

Describe 'Get-BBServerFile.when using a search filter' {
    Init
    GivenARepositoryWithFiles @(
                                    'TestFileA.txt',
                                    'TestFileB.txt',
                                    'FileTest1.doc',
                                    'FileTest2.doc',
                                    'TestFolderA/TestFileA.txt',
                                    'TestFolderA/FileTest1.doc',
                                    'TestFolderA/TestFolderB/TestFileB.txt',
                                    'TestFolderA/TestFolderB/FileTest2.doc'
                               )
    WhenGettingFiles -WithSearchFilter '*.txt'
    ThenItShouldReturn 'TestFileA.txt','TestFileB.txt','TestFolderA/TestFileA.txt','TestFolderA/TestFolderB/TestFileB.txt'
}

Describe 'Get-BBServerFile.when searching a sub-directory' {
    Init
    GivenARepositoryWithFiles @(
                                    'TestFileA.txt',
                                    'TestFileB.txt',
                                    'FileTest1.doc',
                                    'FileTest2.doc',
                                    'TestFolderA/TestFileA.txt',
                                    'TestFolderA/FileTest1.doc',
                                    'TestFolderA/TestFolderB/TestFileB.txt',
                                    'TestFolderA/TestFolderB/FileTest2.doc'
                               )
    WhenGettingFiles -WithPath 'TestFolderA'
    ThenItShouldReturn @(
                            'TestFileA.txt',
                            'FileTest1.doc',
                            'TestFolderB/TestFileB.txt',
                            'TestFolderB/FileTest2.doc'
                        )
}

Describe 'Get-BBServerFile.when searching for a file name that does not exist' {
    Init
    GivenARepositoryWithFiles @( 'File1.txt' )
    WhenGettingFiles -WithSearchFilter 'NonExistentFile.txt'
    ThenItShouldReturn @( )
}

Describe 'Get-BBServerFile.when passed a file path that does not exist' {
    Init
    GivenARepositoryWithFiles @( 'Fil1.txt' )
    WhenGettingFiles -WithPath 'NonExistentFolder'
    ThenItShouldReturn @( )
}