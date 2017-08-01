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

$projectKey = 'GBBSFILE'
$repo = $null
$repoName = $null 
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

function GivenARepositoryWithFiles
{
    [CmdletBinding()]
    param(
        [string[]]
        $Path
    )

    $script:repoName = '{0}{1}' -f ($PSCommandPath | Split-Path -Leaf),[IO.Path]::GetRandomFileName()
    New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null
    $script:repo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName

    $repoClonePath = $repo.links.clone.href | Where-Object { $_ -match 'http' }
    $tempRepoRoot = $TestDrive.FullName
            
    git clone $repoClonePath $tempRepoRoot 2>&1

    Push-Location -Path $tempRepoRoot
    try
    {
        $initialFileList | ForEach-Object {
            New-Item -Path $_ -ItemType 'File' -Force
        }
        git add . 2>&1
        git commit -m 'Staging test files for `Get-BBServerFile` tests' 2>&1
        git push -u origin 2>&1
    }
    finally
    {
        Pop-Location
    }
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
    GivenARepositoryWithFiles @(
                                'FileTest1.doc',
                                'TestFolderA/FileTest1.doc'
                               )
    WhenGettingFiles -WithSearchFilter 'FileTest1.doc'
    ThenItShouldReturn 'FileTest1.doc'
}

Describe 'Get-BBServerFile.when using a search filter' {
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
    GivenARepositoryWithFiles @( 'File1.txt' )
    WhenGettingFiles -WithSearchFilter 'NonExistentFile.txt'
    ThenItShouldReturn @( )
}

Describe 'Get-BBServerFile.when passed a file path that does not exist' {
    GivenARepositoryWithFiles @( 'Fil1.txt' )
    WhenGettingFiles -WithPath 'NonExistentFolder'
    ThenItShouldReturn @( )
}