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

function New-BBServerTag
{
    [CmdletBinding()]
    param(
 <#
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,    
 
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository's project.
        $ProjectKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository.
        $RepositoryKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The tag's name/value.
        $Name,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The commit ID the tag should point to. In the Bitbucket Server API documentation, this is called the `startPoint`.
        $CommitID,
 #>
        [string]
        # An optional message for the commit that creates the tag.
        $Message
 
    )
 
 
 
    Set-StrictMode -Version 'Latest'
 
    #Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    tag-practice
 
 
}
 
function New-BBServerTestConnection
{
    param(
        $ProjectKey,
        $ProjectName
    )

    $credentialPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\.bbservercredential' -Resolve
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
<#
    This works now, but now I need to pull out all of the git commands into a test suite and pull together just the rest related
    commands into the actual new-bbservertag function, then write some other tests.
    
    Also, don't forget that we've created a bunch of projects on BBServer that will likely need to be removed? Not sure about that 
    though, as my local instance of BBserver probably doesn't have any effect on the outside world.

    To access BBserver, get the login info from the _netrc file in the env:home directory. The browse URL is contained in the repo.links
#>
function tag-practice
{
    param()
    function New-TestProjectInfo
    {
        $key = ([IO.Path]::GetRandomFileName()) -replace '[^A-Za-z0-9_]','_'
        $key -replace '^\d+',''
        'New-BBServerProject-New-Project-{0}' -f [IO.Path]::GetRandomFileName()
    }
    Push-Location
    $testDrive = ni -Name 'TestDrive' -ItemType 'Directory' -Path 'C:\Users\esmelser\Projects' -Force
    Set-Location -path $testDrive

    #setup
    git init
    $conn = New-BBServerTestConnection
    $key,$name = New-TestProjectInfo
    $description = 'description'
    $project = New-BBServerProject -Connection $conn -Key $key -Name $name -Description $description
    $repo = New-BBServerRepository -Connection $conn -ProjectKey $key -Name $name
    $cloneRepo = $repo.links.clone | Where-Object { $_.name -eq 'http' }  | Select-Object -ExpandProperty 'href'

    #create netrc file to maintain credentials for commit and push
    $netrcFile = New-Item -Name '_netrc' -Force -Path $env:HOME -ItemType 'file' -Value @"
machine $(([uri]$cloneRepo).Host)
login $($conn.Credential.UserName)
password $($conn.Credential.GetNetworkCredential().Password)
"@

    #clone, commit and push a new file to the new repo
    git clone $cloneRepo
    $newFile = New-Item -Name 'fubarFile' -ItemType 'file' -Value 'newFile!!' -Force
    git add $newFile
    git commit -am ('adding new file for project-key: {0}' -f $key)
    
    #get the HEAD commit hash
    $commitHash = git rev-parse HEAD
    
    git push --set-upstream $cloneRepo master
    
    $newTag = @{
        force = "true"
        name = "v1.4"
        startPoint = $commitHash
        message = "this is my message"
        type = "ANNOTATED"
                }
    $something = $newTag | Invoke-BBServerRestMethod -Connection $conn -Method Post -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $key, $name)
    Pop-Location
    Remove-Item -Path $testDrive -Force -Recurse
    Remove-Item -Path $netrcFile -Force -Recurse
}

