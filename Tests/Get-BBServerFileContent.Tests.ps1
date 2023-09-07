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
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\GitAutomation') -Force

$projectKey = 'GETFILECONTENT'
$repo = $null
$repoName = $null 
$repoRoot = $null
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerFileContent Tests'
$content = $null

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoRoot = $repo | Initialize-TestRepository -Connection $bbConnection
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'
    $script:content = $null

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

function GivenFile
{
    param(
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [String]$WithContent
    )

    Push-Location $repoRoot
    try
    {
        [Environment]::CurrentDirectory = $repoRoot
        $op = 'Modifying'
        if( -not (Test-Path -Path $Path) )
        {
            New-Item -Path $Path -ItemType 'File' | Out-Null
            $op = 'Adding'
        }
        [IO.File]::WriteAllText($Path, $WithContent)
        
        Add-GitItem -Path $Path
        Save-GitCommit -Message ("$($op) file ""$($Path)"".") | Out-String | Write-Debug
        Send-GitCommit -Credential $bbConnection.Credential
    }
    finally
    {
        Pop-Location
        [Environment]::CurrentDirectory = (Get-Location).Path
    }
}

function WhenGettingContentOf
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [String]$AtCommitish
    )

    $conditionalParams = @{}
    if( $AtCommitish )
    {
        $conditionalParams['Commitish'] = $AtCommitish
    }
    
    $script:content = Get-BBServerFileContent -Connection $bbConnection `
                                              -ProjectKey $projectKey `
                                              -RepoName $repoName `
                                              -Path $Path `
                                              @conditionalParams
}

function ThenContentIs
{
    param(
        [String]$ExpectedString
    )

    $content | Should -Be $ExpectedString
}

Describe 'Get-BBServerFile.when getting a file with one line' {
    It 'should return file content' {
        Init
        GivenFile 'fubar' -WithContent 'mycontent'
        WhenGettingContentOf 'fubar'
        ThenContentIs 'mycontent'
    }
}

Describe 'Get-BBServerFile.when getting a multiline file' {
    It 'should return file content as one string' {
        $content = "so`nmany`nlines`nit`nis`nhard`nto`nkeep`ntrack`nof`nthem`nall"
        Init
        GivenFile 'second file' -WithContent $content
        WhenGettingContentOf 'second file'
        ThenContentIs $content
    }
}

Describe 'Get-BBServerFile.when getting file at specific commit' {
    It 'should return content at that commit' {
        Init
        GivenFile 'THIRD!' -WithContent '1'
        GivenFile 'THIRD!' -WithContent '2'
        GivenFile 'THIRD!' -WithContent '3'
        WhenGettingContentOf 'THIRD!' -AtCommitish 'HEAD~2'
        ThenContentIs '1'
    }
}

Describe 'Get-BBServerFile.when getting contents from a json file' {
    It 'should return contents as json' {
        $content = @"
[
    {
        "name":  "test",
        "number":  1
    },
    {
        "name":  "test2",
        "port":  8099
    }
]
"@
        Init
        GivenFile 'test file' -WithContent $content
        WhenGettingContentOf 'test file'
        ThenContentIs $content
    }
}