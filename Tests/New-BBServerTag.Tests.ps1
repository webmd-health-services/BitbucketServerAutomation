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

function New-BBServerTestConnection
{
    param(
        $ProjectKey,
        $ProjectName
    )

    $credentialPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.bbservercredential' -Resolve
    if( -not $credentialPath )
    {
        throw ('The credential to a local Bitbucket Server instance does not exist. Please run init.ps1 in the root of the repository to install a local Bitbucket Server. This process creates a credential and saves it in a secure format. The automated tests use this credential to connect to Bitbucket Server when running tests.')
    }
    $credential = Import-Clixml -Path $credentialPath
    if( -not $credential )
    {
        throw ('The credential in ''{0}'' is not valid. Please delete this file, uninstall your local Bitbucket Server instance (with the Uninstall-BitbucketServer.ps1 PowerShell script in the root of the repository), and re-run init.ps1.')
    }
    $conn = New-BBServerConnection -Credential $credential -Uri ('http://{0}:7990' -f $env:COMPUTERNAME.ToLowerInvariant())

    if( $ProjectKey -and $ProjectName )
    {
        New-BBServerProject -Connection $conn -Key $ProjectKey -Name $ProjectName -ErrorAction Ignore | Out-Null
    }

    return $conn
}

function New-TestProjectInfo
{
    $key = ([IO.Path]::GetRandomFileName()) -replace '[^A-Za-z0-9_]','_'
    $key -replace '^\d+',''
    'New-BBServerProject-New-Project-{0}' -f [IO.Path]::GetRandomFileName()
}

#setup
Push-Location
$conn = New-BBServerTestConnection
$key,$repoName = New-TestProjectInfo
$project = New-BBServerProject -Connection $conn -Key $key -Name $repoName -Description 'description'
$repository = New-BBServerRepository -Connection $conn -ProjectKey $key -Name $repoName
$cloneRepo = $repository.links.clone | Where-Object { $_.name -eq 'http' }  | Select-Object -ExpandProperty 'href'
$global:commitNumber = 0

#create netrc file to maintain credentials for commit and push
$netrcFile = New-Item -Name '_netrc' -Force -Path $env:HOME -ItemType 'file' -Value @"
machine $(([uri]$cloneRepo).Host)
login $($conn.Credential.UserName)
password $($conn.Credential.GetNetworkCredential().Password)
"@

<#
    Don't forget that we've created a bunch of projects on BBServer that will likely need to be removed? Not sure about that 
    though, as my local instance of BBserver probably doesn't have any effect on the outside world.

    To access BBserver, get the login info from the _netrc file in the env:home directory. The browse URL is contained in the repo.links
#>

function GivenAValidCommit
{
    Set-Location $TestDrive.FullName
    git init | Out-Null
    #clone, commit and push a new file to the new repo
    git clone $cloneRepo
    git remote add origin $cloneRepo
    git pull origin master | Out-Null
    $newFile = New-Item -Name 'commitfile' -ItemType 'file' -Force -Value ('newFile {0}!!' -f $global:commitNumber) 
    git add $newFile
    git commit -m ('adding file, commit no {0} for project-key: {1}' -f $global:commitNumber++, $key) | Out-Null
    
    #get the HEAD commit hash
    $commitHash = git rev-parse HEAD
    
    git push --set-upstream $cloneRepo master | Out-Null

    return $commitHash

}

function WhenTaggingTheCommit
{
    param(
        [String]
        $CommitHash,

        [String]
        $TagName,

        [String]
        $Message
    )

    $optionalParams = @{}
    if ($Message)
    {
        $optionalParams['Message'] = $Message
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
        $TagResult
    )

    it 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
    it 'should successfully tag the commit' {
        $TagResult | Should be $true
    }
    <#
    TODO: implement a way of checking to see that the remote repo was tagged with the appropriate tag.
    it ('should apply the {0} tag in the remote repo' -f $TagName) {
        #not sure how to verify the tag yet outside the scope of the function yet. Get-Tag?
    }
    #>
}

function ThenTheCommitShouldNotBeTagged
{
        param(
        [String]
        $ErrorMessage,
        
        [Bool]
        $TagResult 
        
    )

    it 'should throw errors' {
        $Global:Error[0] | Should match 'Unable to tag commit'
        $Global:Error[1] | Should match $ErrorMessage
    }
    it 'should not successfully tag the commit' {
        $TagResult | Should Be $false
    }
    <#
    TODO: implement a way of checking to see that the remote repo was tagged with the appropriate tag.
    it ('should not apply the {0} tag in the remote repo' -f $TagName) {
        #not sure how to verify the tag yet outside the scope of the function yet. Get-Tag?
    }
    #>
    
}

Describe 'New-BBServerTag.when tagging a new commit' {
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    $result = WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagResult $result
}

Describe 'New-BBServerTag.when tagging an invalid commit' {
    $tagName = 'v1.4'
    $tagMessage = 'message'
    $commit = 'notactuallyacommithash'
    $error = ("'{0}' is an invalid tag point." -f $commit)
    $result = WhenTaggingTheCommit -CommitHash $commit -TagName $tagName -Message $tagMessage
    ThenTheCommitShouldNotBeTagged -TagResult $result -ErrorMessage $error
}

Describe 'New-BBServerTag.when re-tagging a new commit that already has a tag' {
    $tagMessage = 'message'
    $commit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $commit -TagName 'v1.4' -Message $tagMessage
    $result = WhenTaggingTheCommit -CommitHash $commit -TagName 'v1.5' -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagResult $result
}

Describe 'New-BBServerTag.when tagging two commits with the same tag' {
    $tagMessage = 'message'
    $tagName = 'v1.4'
    $firstcommit = GivenAValidCommit
    $secondcommit = GivenAValidCommit
    WhenTaggingTheCommit -CommitHash $firstcommit -TagName $tagName -Message $tagMessage
    $result = WhenTaggingTheCommit -CommitHash $secondcommit -TagName $tagName -Message $tagMessage
    ThenTheCommitShouldBeTagged -TagResult $result
}

#teardown
Pop-Location
Remove-Item -Path $netrcFile -Force -Recurse