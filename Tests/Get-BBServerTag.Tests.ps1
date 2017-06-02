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

Set-StrictMode -Version 'Latest'
#Requires -Version 4

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

#setup
$conn = New-BBServerTestConnection
$key,$repoName = New-TestProjectInfo
$project = New-BBServerProject -Connection $conn -Key $key -Name $repoName -Description 'description'
$repository = New-BBServerRepository -Connection $conn -ProjectKey $key -Name $repoName
$cloneRepo = $repository.links.clone | Where-Object { $_.name -eq 'http' }  | Select-Object -ExpandProperty 'href'
$global:commitNumber = 0
$gitVersion = git --version
$DebugPreference = 'Continue' 

Write-Debug -Message ('git version = {0}' -f $gitVersion)
Write-Debug -Message ('env:USERPROFILE = {0}' -f $env:USERPROFILE)
Write-Verbose -Message ('git version = {0}' -f $gitVersion)
Write-Verbose -Message ('env:USERPROFILE = {0}' -f $env:USERPROFILE)
#create netrc file to maintain credentials for commit and push
$netrcFile = New-Item -Name '_netrc' -Force -Path $env:USERPROFILE -ItemType 'file' -Value @"
machine $(([uri]$cloneRepo).Host)
login $($conn.Credential.UserName)
password $($conn.Credential.GetNetworkCredential().Password)
"@
Write-Verbose -Message ('Should place .netrc: {0}' -f $netrcFile)
Write-Debug -Message ('Should place .netrc: {0}' -f $netrcFile)

function GivenARepositoryWithTaggedCommits
{
    param(
        [Int]
        $WithNumberOfTags,

        [String]
        $WithTagNamed
    )

    Push-Location $TestDrive.FullName
    try
    {
        git init 2>&1 | Write-Debug
        #clone, commit and push a new file to the new repo
        git clone $cloneRepo 2>&1 | Write-Debug
        git remote add origin $cloneRepo 2>&1 | Write-Debug
        git pull origin master 2>&1 | Write-Debug
        $newFile = New-Item -Name 'commitfile' -ItemType 'file' -Force -Value ('newFile {0}!!' -f $global:commitNumber) 
        git add $newFile 2>&1 | Write-Debug
        git commit -m ('adding file, commit no {0} for project-key: {1}' -f $global:commitNumber++, $key) 2>&1 | Write-Debug
    
        #get the HEAD commit hash
        $commitHash = git rev-parse HEAD 2>$null
    
        git push --set-upstream $cloneRepo master 2>&1 | Write-Debug

        if( $WithNumberOfTags )
        {
            for( $idx = 0; $idx -lt $WithNumberOfTags; ++$idx )
            {
                $newFile = New-Item -Name ('newfile{0}' -f $idx) -ItemType 'file' -Force -Value ('new file # {0}!!' -f $idx)
                git add $newFile 2>&1 | Write-Debug
                git commit -m ('adding file, commit no {0} for project-key: {1}' -f $idx, $key) 2>&1 | Write-Debug
                $commitHash = git rev-parse HEAD 2>$null
                git push 2>&1 | Write-Debug

                New-BBServerTag -Connection $conn -ProjectKey $key -Name $idx -CommitID $commitHash -RepositoryKey $repoName
            }
        }
        if( $WithTagNamed )
        {
            $newFile = New-Item -Name 'newfile' -ItemType 'file' -Force -Value 'new file!!'
            git add $newFile 2>&1 | Write-Debug
            git commit -m ('adding file, commit for project-key: {0}' -f $key) 2>&1 | Write-Debug
            $commitHash = git rev-parse HEAD 2>$null
            git push 2>&1 | Write-Debug

            New-BBServerTag -Connection $conn -ProjectKey $key -Name $WithTagNamed -CommitID $commitHash -RepositoryKey $repoName
        }
    }
    finally
    {
        Pop-Location
    }
}

function WhenGettingTags
{
    param(
    )
    return Get-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName
}

function ThenTagsShouldBeObtained
{
    param(
        [Object]
        $WithTags,

        [Int]
        $NumberOfTags,

        [String]
        $WithTagNamed
    )
    if( $WithTagNamed )
    {
        It ('should have named the tag {0}' -f $WithTagNamed) {
            $WithTags.values[0].displayId | should Be $WithTagNamed
        }
    }
    else
    {
        It ('should get {0} tags' -f $NumberOfTags) {
            $WithTags.size | should Be $NumberOfTags
        }
        
    }
}

Describe 'Get-BBServerTag when getting more tags than the default limit' {
    $numTags = 26
    GivenARepositoryWithTaggedCommits -WithNumberOfTags $numTags
    $tags = WhenGettingTags
    ThenTagsShouldBeObtained -WithTags $tags -NumberOfTags $numTags
}

Describe 'Get-BBServerTag when getting the most recent tag' {
    $tagName ="thisIsTheMostRecentTag"
    GivenARepositoryWithTaggedCommits -WithTagNamed $tagName
    $tags = WhenGettingTags
    ThenTagsShouldBeObtained -WithTags $tags -NumberOfTags 1 -WithTagNamed $tagName
}

#teardown
Remove-Item -Path $netrcFile -Force -Recurse