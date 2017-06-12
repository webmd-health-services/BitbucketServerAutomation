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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$projectKey = 'GBBSFILE'
$repoName = 'RepositoryWithFiles'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerFile Tests'

New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null
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
    )

    $getFiles = Get-BBServerFile -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -ErrorAction Ignore
    if( !$getFiles )
    {
        $targetRepo = Get-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName
        $repoClonePath = $targetRepo.links.clone.href | Where-Object { $_ -match 'http' }
        $tempRepoRoot = Join-Path -Path $env:TEMP -ChildPath ('{0}+{1}' -f $RepoName, [IO.Path]::GetRandomFileName())
        New-Item -Path $tempRepoRoot -ItemType 'Directory' | Out-Null
            
        Push-Location -Path $tempRepoRoot
        try
        {
            git clone $repoClonePath $repoName
            cd $repoName
            $initialFileList | ForEach-Object {
                New-Item -Path $_ -ItemType 'File' -Force 2>&1 | Out-Null
            }
            git add .
            git commit -m 'Staging test files for `Get-BBServerFile` tests'
            git push -u origin
        }
        finally
        {
            Pop-Location
            Remove-Item -Path $tempRepoRoot -Recurse -Force
        }
    }
}

function WhenGettingFiles
{
    [CmdletBinding()]
    param(
        [switch]
        $FromTheRoot,

        [switch]
        $WithNoSearchFilter,

        [string]
        $WithSearchFilter,

        [string]
        $WithFilePath
    )

    $Global:Error.Clear()

    $bbServerFileParams = @{}
    if( $WithSearchFilter )
    {
        $bbServerFileParams['FileName'] = $WithSearchFilter
    }
    
    if( $WithFilePath )
    {
        $bbServerFileParams['FilePath'] = $WithFilePath
    }
    
    $getFiles = Get-BBServerFile -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName @bbServerFileParams -ErrorAction SilentlyContinue
    
    if( $FromTheRoot -and $WithNoSearchFilter )
    {
        It 'should retrieve exactly 8 files' {
            $getFiles.Count | Should Be 8
        }

        $getFiles | ForEach-Object {
            It ('result set should include {0}' -f $_) {
                $initialFileList -contains $_ | Should Be True
            }
        }
    }

    if( $FromTheRoot -and $WithSearchFilter -eq 'FileTest1.doc' )
    {
        $searchResultsList = ('FileTest1.doc', 'TestFolderA/FileTest1.doc')

        It 'should retrieve exactly 2 files' {
            $getFiles.Count | Should Be 2
        }

        $getFiles | ForEach-Object {
            It ('result set should include {0}' -f $_) {
                $searchResultsList -contains $_ | Should Be True
            }
        }
    }

    if( $FromTheRoot -and $WithSearchFilter -eq '*.txt' )
    {
        $searchResultsList = ('TestFileA.txt', 'TestFileB.txt', 'TestFolderA/TestFileA.txt', 'TestFolderA/TestFolderB/TestFileB.txt')

        It 'should retrieve exactly 4 files' {
            $getFiles.Count | Should Be 4
        }

        $getFiles | ForEach-Object {
            It ('result set should include {0}' -f $_) {
                $searchResultsList -contains $_ | Should Be True
            }
        }
    }

    if( $FromTheRoot -and $WithSearchFilter -eq 'File*' )
    {
        $searchResultsList = ('FileTest1.doc', 'FileTest2.doc', 'TestFolderA/FileTest1.doc', 'TestFolderA/TestFolderB/FileTest2.doc')

        It 'should retrieve exactly 4 files' {
            $getFiles.Count | Should Be 4
        }

        $getFiles | ForEach-Object {
            It ('result set should include {0}' -f $_) {
                $searchResultsList -contains $_ | Should Be True
            }
        }
    }

    if( $FromTheRoot -and $WithSearchFilter -eq '*1*' )
    {
        $searchResultsList = ('FileTest1.doc', 'TestFolderA/FileTest1.doc')

        It 'should retrieve exactly 2 files' {
            $getFiles.Count | Should Be 2
        }

        $getFiles | ForEach-Object {
            It ('result set should include {0}' -f $_) {
                $searchResultsList -contains $_ | Should Be True
            }
        }
    }

    if( $WithFilePath -eq 'TestFolderA' -and $WithNoSearchFilter )
    {
        $searchResultsList = ('TestFileA.txt', 'FileTest1.doc', 'TestFolderB/TestFileB.txt', 'TestFolderB/FileTest2.doc')

        It 'should retrieve exactly 4 files' {
            $getFiles.Count | Should Be 4
        }
        
        $getFiles | ForEach-Object {
            It ('result set should include {0}' -f $_) {
                $searchResultsList -contains $_ | Should Be True
            }
        }
    }

    if( $WithFilePath -eq 'TestFolderA/TestFolderB' -and $WithSearchFilter -eq '*.doc' )
    {
        $searchResultsList = ('FileTest2.doc')
        
        $getFiles | ForEach-Object {
            It ('result set should include only {0}' -f $_) {
                $searchResultsList -contains $_ | Should Be True
            }
        }
    }

    if( $FromTheRoot -and $WithSearchFilter -eq 'NonExistentFile.txt' )
    {
        $searchResultsList = ('FileTest1.doc', 'FileTest2.doc', 'TestFolderA/FileTest1.doc', 'TestFolderA/TestFolderB/FileTest2.doc')

        It 'should not retrieve any files' {
            $getFiles | Should BeNullOrEmpty
        }
    }

    if( $WithFilePath -eq 'NonExistentFolder' )
    {
        It 'should throw an error that the file path does not exist' {
            $Global:Error | Should Match ('The path "{0}" does not exist' -f $WithFilePath)
        }
    }
    else
    {
        It 'should not throw any errors' {
            $Global:Error | Should BeNullOrEmpty
        }
    }
}

Describe 'Get-BBServerFile.when returning all files from the root of the repository' {
    GivenARepositoryWithFiles
    WhenGettingFiles -FromTheRoot -WithNoSearchFilter
}

Describe 'Get-BBServerFile.when returning files from the root named ''FileTest1.doc''' {
    GivenARepositoryWithFiles
    WhenGettingFiles -FromTheRoot -WithSearchFilter 'FileTest1.doc'
}

Describe 'Get-BBServerFile.when returning files from the root that match wildcard search ''*.txt''' {
    GivenARepositoryWithFiles
    WhenGettingFiles -FromTheRoot -WithSearchFilter '*.txt'
}

Describe 'Get-BBServerFile.when returning files from the root that begin with ''File''' {
    GivenARepositoryWithFiles
    WhenGettingFiles -FromTheRoot -WithSearchFilter 'File*'
}

Describe 'Get-BBServerFile.when returning files from the root that contain the number ''1''' {
    GivenARepositoryWithFiles
    WhenGettingFiles -FromTheRoot -WithSearchFilter '*1*'
}

Describe 'Get-BBServerFile.when returning files from a sub-directory named ''TestFolderA''' {
    GivenARepositoryWithFiles
    WhenGettingFiles -WithFilePath 'TestFolderA' -WithNoSearchFilter
}

Describe 'Get-BBServerFile.when returning files from a sub-directory named ''TestFolderA/TestFolderB''' {
    GivenARepositoryWithFiles
    WhenGettingFiles -WithFilePath 'TestFolderA/TestFolderB' -WithSearchFilter '*.doc'
}

Describe 'Get-BBServerFile.when searching for a file name that does not exist' {
    GivenARepositoryWithFiles
    WhenGettingFiles -FromTheRoot -WithSearchFilter 'NonExistentFile.txt'
}

Describe 'Get-BBServerFile.when passed a file path that does not exist' {
    GivenARepositoryWithFiles
    WhenGettingFiles -WithFilePath 'NonExistentFolder' -WithNoSearchFilter
}