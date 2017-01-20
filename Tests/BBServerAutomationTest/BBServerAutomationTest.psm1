
Set-StrictMode -Version 'Latest'

function New-TestRepoName
{
    'BitbucketServerAutomationTest{0}' -f [IO.Path]::GetRandomFileName()
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
