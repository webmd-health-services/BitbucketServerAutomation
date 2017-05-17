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

function tag-practice
{
    param()
    function New-TestProjectInfo
    {
        $key = ([IO.Path]::GetRandomFileName()) -replace '[^A-Za-z0-9_]','_'
        $key -replace '^\d+',''
        'New-BBServerProject-New-Project-{0}' -f [IO.Path]::GetRandomFileName()
    }

    $conn = New-BBServerTestConnection
    #$projectKey = 'NBBSPROJ'
    $key,$name = New-TestProjectInfo
    #$key = $projectKey
    #$name = New-TestRepoName
    $description = 'description'
    $project = New-BBServerProject -Connection $conn -Key $key -Name $name -Description $description
    $repo = New-BBServerRepository -Connection $conn -ProjectKey $key -Name $name

    #move into the test drive
    $testDrive = ni -Name 'TestDrive' -ItemType 'Directory'
    Set-Location '.\TestDrive'
    #clone the repo
    #either figure out how to configure the permissions or make it so that anyone can commit
    git clone $repo.links.clone[1].href
    #create a new file
    $newFile = ni -Name 'fubarFile' -ItemType 'file'
    #commit and push the new file to the new cloned repo
    git add $newFile
    git commit -am 'adding new file'
    git push
    #tag the commit
    #will probably have to figure out how to access the SHA1 here
    $newTag = @{
        name = "myTag"
        startPoint = "asdfgouihaerg"
        message = "this is my message"
                }
    $something = $newTag | Invoke-BBServerRestMethod -Connection $conn -Method Post -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $key, $name)
}

 <#
 $newTag = @{
        tag = "v0.0.1";
        message = "test";
        object = "c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c";
        type = "commit";
        tagger = @{
            name = "Scott Chacon";
            email = "schacon@gmail.com";
            date = "2011-06-17T14:53:35-07:00";
                }
        }

$projectKey = 'NBBSREPO'

$conn = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'New-BBServerTag Tests'

$repoName = New-TestRepoName

$repo = $newRepoInfo | Invoke-BBServerRestMethod -Connection $conn -Method Post -ApiName 'api' -ResourcePath ('projects/{0}/repos' -f $ProjectKey)
 
 $newTagMinusTagger = @{
        tag = "v0.0.1";
        message = "test";
        object = "c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c";
        type = "commit";
        } 



 
 
 
 #>