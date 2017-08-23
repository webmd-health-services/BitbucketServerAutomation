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
Push-Location
$conn = New-BBServerTestConnection
$key,$repoName = New-TestProjectInfo
$project = New-BBServerProject -Connection $conn -Key $key -Name $repoName -Description 'description'
$repository = $null
$global:commitNumber = 0
$gitVersion = git --version 2>&1
#$DebugPreference = 'Continue' 
Write-Debug -Message ('git version = {0}' -f $gitVersion)
Write-Debug -Message ('env:USERPROFILE = {0}' -f $env:USERPROFILE)
Write-Verbose -Message ('git version = {0}' -f $gitVersion)
Write-Verbose -Message ('env:USERPROFILE = {0}' -f $env:USERPROFILE)
#create netrc file to maintain credentials for commit and push
$netrcFile = New-Item -Name '_netrc' -Force -Path $env:USERPROFILE -ItemType 'file' -Value @"
machine $($env:COMPUTERNAME)
login $($conn.Credential.UserName)
password $($conn.Credential.GetNetworkCredential().Password)
"@
Write-Debug -Message ('Should place .netrc: {0}' -f $netrcFile)
Write-Verbose -Message ('Should place .netrc: {0}' -f $netrcFile)
<#
    Don't forget that we've created a bunch of projects on BBServer that will likely need to be removed? Not sure about that 
    though, as my local instance of BBserver probably doesn't have any effect on the outside world.

    To access BBserver, get the login info from the _netrc file in the env:home directory. The browse URL is contained in the repo.links
#>

function GivenARepository
{
    Push-Location $TestDrive.FullName
    try
    {
        $script:repoName = '{0}-{1}' -f ($PSCommandPath | Split-Path -Leaf),[IO.Path]::GetRandomFileName()
        $script:repository = New-BBServerRepository -Connection $conn -Name $repoName -ProjectKey $key
        $cloneRepo = $repository.links.clone | Where-Object { $_.name -eq 'http' }  | Select-Object -ExpandProperty 'href'
        git init 2>&1 | Write-Debug
        #clone, commit and push a new file to the new repo
        git clone $cloneRepo 2>&1 | Write-Debug
        git remote add origin $cloneRepo 2>&1 | Write-Debug
        git pull origin master 2>&1 | Write-Debug
        $newFile = New-Item -Name 'commitfile' -ItemType 'file' -Force -Value ('newFile {0}!!' -f $global:commitNumber) 
        git add $newFile 2>&1 | Write-Debug
        git commit -m ('adding file, commit no {0} for project-key: {1}' -f $global:commitNumber++, $key) 2>&1 | Write-Debug
    
        #get the HEAD commit hash
        $commitHash = git rev-parse HEAD 2>&1
    
        git push --set-upstream $cloneRepo master 2>&1 | Write-Debug 

        return $commitHash
    }
    finally
    {
        Pop-Location
    }
}

function GivenAValidCommit
{
    Push-Location $TestDrive.FullName
    try
    {
        if( -not (git rev-parse HEAD 2>$null) )
        {
            GivenARepository | Write-Debug
        }
        
        $newFile = New-Item -Name 'commitfile' -ItemType 'file' -Force -Value ('newFile {0}!!' -f $global:commitNumber) 
        git add $newFile 2>&1 | Write-Debug
        git commit -m ('adding file, commit no {0} for project-key: {1}' -f $global:commitNumber++, $key) 2>&1 | Write-Debug
    
        #get the HEAD commit hash
        $commitHash = git rev-parse HEAD 2>&1
    
        git push origin master 2>&1 | Write-Debug 

        return $commitHash
    }
    finally
    {
        Pop-Location
    }
}

function WhenTaggingTheCommit
{
    [CmdletBinding()]
    param(
        [String]
        $CommitHash,

        [String]
        $TagName,

        [String]
        $Message,

        [Switch]
        $Force,

        [String]
        $Type
    )

    $optionalParams = @{}
    if($Message)
    {
        $optionalParams['Message'] = $Message
    }
    if($Force)
    {
        $optionalParams['Force'] = $true
    }
    if($Type)
    {
        $optionalParams['Type'] = $Type
    }
    $global:Error.Clear()
    try
    {
        New-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName -name $TagName -CommitID $commitHash @optionalParams
    }
    catch
    {
        return $false
    }
    return $true
}

function ThenTheCommitShouldBeTagged
{
    param(
        [bool]
        $TagResult,

        [String]
        $TagName,

        [String]
        $CommitHash
    )

    Push-Location $TestDrive.FullName
    try
    {
        it 'should not throw any errors' {
            $Global:Error | Should BeNullOrEmpty
        }
        it 'should successfully tag the commit' {
            $TagResult | Should be $true
        }
    
        git fetch --all 2>&1 | Write-Debug
        $tags = git tag --points-at $CommitHash 2>&1

        it ('should apply the {0} tag to commit {1} in the remote repo' -f $TagName, $CommitHash) {
            $tags | Where-Object { $_ -match $TagName } | Should -Not -BeNullOrEmpty
        }
    }
    finally
    {
        Pop-Location
    }
}

function ThenTheCommitShouldNotBeTagged
{
        param(
        [String]
        $ErrorMessage,
        
        [String]
        $CommitHash        
    )

    it 'should throw errors' {
        $Global:Error[0] | Should match 'Unable to tag commit'
        $Global:Error[1] | Should match $ErrorMessage
    }
 
    git fetch --all 2>&1 | Write-Debug
    $tags = git tag --points-at $CommitHash 2>$null
 
    it ('should not apply the {0} tag to commit {1} in the remote repo' -f $TagName, $CommitHash) {
        $tags | Should BeNullOrEmpty 
    }
    
}

Describe 'New-BBServerTag.when tagging a new commit' {
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    $result = WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagResult $result -TagName $tagName -CommitHash $commit
}

Describe 'New-BBServerTag.when tagging an invalid commit' {
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = 'notactuallyacommithash'
    $error = ("'{0}' is an invalid tag point." -f $commit)
    WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage -ErrorAction SilentlyContinue
    ThenTheCommitShouldNotBeTagged -ErrorMessage $error -CommitHash $commit
}

Describe 'New-BBServerTag.when re-tagging a new commit that already has a tag' {
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $commit -TagName 'v1.4' -Message $tagMessage
    $result = WhenTaggingTheCommit -CommitHash $commit -TagName 'v1.5' -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagResult $result -TagName 'v1.5' -CommitHash $commit
}

Describe 'New-BBServerTag.when tagging two commits with the same tag' {
    $tagMessage = 'message'
    $tagName = 'v1.4'
    $firstcommit = GivenAValidCommit
    $secondcommit = GivenAValidCommit
    $error = ("Tag '{0}' already exists in repository" -f $tagName)
    WhenTaggingTheCommit -CommitHash $firstcommit -TagName $tagName -Message $tagMessage 
    WhenTaggingTheCommit -CommitHash $secondcommit -TagName $tagName -Message $tagMessage -ErrorAction SilentlyContinue
    ThenTheCommitShouldNotBeTagged -ErrorMessage $error -CommitHash $secondcommit
}

Describe 'New-BBServerTag.when tagging two commits with the same tag and including the Force switch' {
    $tagMessage = 'message'
    $tagName = 'v1.4'
    $firstcommit = GivenAValidCommit
    $secondcommit = GivenAValidCommit
    $error = ("Tag '{0}' already exists in repository" -f $tagName)
    WhenTaggingTheCommit -CommitHash $firstcommit -TagName $tagName -Message $tagMessage
    $result = WhenTaggingTheCommit -CommitHash $secondcommit -TagName $tagName -Message $tagMessage -Force
    ThenTheCommitShouldBeTagged -TagResult $result -TagName $tagName -CommitHash $secondcommit
}

Describe 'New-BBServerTag.when tagging a new commit with an Annotated Tag' {
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    $result = WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage -Type 'ANNOTATED' -Force
    ThenTheCommitShouldBeTagged -TagResult $result -TagName $tagName -CommitHash $commit
}

Describe 'New-BBServerTag.when tagging a new commit with an Invalid Tag type' {
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    $error = 'An error occurred while processing the request. Check the server logs for more information.'
    WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage -Type 'INVALID' -ErrorAction SilentlyContinue
    ThenTheCommitShouldNotBeTagged -TagName $tagName -CommitHash $commit -ErrorMessage $error
}

#teardown
Pop-Location
Remove-Item -Path $netrcFile -Force -Recurse