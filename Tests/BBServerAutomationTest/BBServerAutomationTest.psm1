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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\PSModules\GitAutomation') -Force

function New-TestRepoName
{
    'BitbucketServerAutomationTest-{0}' -f [IO.Path]::GetRandomFileName()
}

function Initialize-TestRepository
{
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        # An object representing the Bitbucket server repository to clone locally. Pipe the output of `New-BBServerTestRepository` to this function.
        [object]
        $InputObject,

        [Parameter(Mandatory)]
        $Connection,

        [switch]
        $NoInitialCommit
    )

    $cloneUri = $InputObject.links.clone.href | Where-Object { $_ -match 'http' }
    $credential = $Connection.Credential
    $testRepo = Join-Path -Path $TestDrive.FullName -ChildPath ($InputObject | Select-Object -ExpandProperty 'name')

    Copy-GitRepository -Source $cloneUri -DestinationPath $testRepo -Credential $credential | Write-Debug

    if (-not $NoInitialCommit)
    {
        New-TestRepoCommit -RepoRoot $testRepo -Connection $Connection | Write-Debug
    }

    return $testRepo
}

function New-TestRepoCommit
{
    param(
        [Parameter(Mandatory, ParameterSetName='RepoRoot')]
        [string]
        $RepoRoot,

        [Parameter(Mandatory)]
        [object]
        $Connection,

        [string[]]
        $Filename = ([IO.Path]::GetRandomFileName())
    )

    $credential = $Connection.Credential

    Push-Location -Path $RepoRoot
    try
    {
        $Filename | ForEach-Object {
            New-Item -Path $_ -ItemType File -Force | Write-Debug
            Add-GitItem -Path $_ | Write-Debug
        }

        $commit = Save-GitCommit -Message ('Add file {0}' -f ($Filename -join ', '))
        Send-GitCommit -Credential $credential | Write-Debug
    }
    finally
    {
        Pop-Location
    }

    return $commit
}

function New-BBServerTestRepository
{
    param(
        [Parameter(Mandatory)]
        [object]
        $Connection,

        [Parameter(Mandatory)]
        [string]
        $ProjectKey
    )

    New-BBServerRepository -Connection $Connection -ProjectKey $ProjectKey -Name (New-TestRepoName)
}

function New-BBServerTestConnection
{
    [CmdletBinding(DefaultParameterSetName='NoProject')]
    param(
        [Parameter(Mandatory, ParameterSetName='WithProject')]
        [string]
        $ProjectKey,

        [Parameter(Mandatory, ParameterSetName='WithProject')]
        [string]
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

    $conn = New-BBServerConnection -Credential $credential -Uri 'http://127.0.0.1:7990'

    if ($ProjectKey)
    {
        $projectNotExists = $null -eq (Get-BBServerProject -Connection $conn | Where-Object { $_.key -eq $ProjectKey })

        if ($projectNotExists)
        {
            New-BBServerProject -Connection $conn -Key $ProjectKey -Name $ProjectName | Write-Debug
        }
    }

    return $conn
}

function Remove-BBServerTestRepository
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        $ProjectKey
    )

    Get-BBServerRepository -Connection $Connection -ProjectKey $ProjectKey -Name 'BitbucketServerAutomationTest*' | Remove-BBServerRepository -Connection $Connection
}

function New-TestProjectInfo
{
    $key = ([IO.Path]::GetRandomFileName()) -replace '[^A-Za-z0-9_]','_'
    $key -replace '^\d+',''
    'New-BBServerProject-New-Project-{0}' -f [IO.Path]::GetRandomFileName()
}

