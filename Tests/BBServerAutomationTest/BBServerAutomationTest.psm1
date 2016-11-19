
Set-StrictMode -Version 'Latest'

$serverJsonPath = Join-Path -Path $PSScriptRoot -ChildPath 'server.json'
if( -not (Test-Path -Path $serverJsonPath -PathType Leaf) )
{
    throw (@'
Can''t run tests. Configuration file ''{0}'' does not exist. Please 
create this file from the template ''{1}.sample''. 

This file should contain an encrypted password to use to connect to 
Bitbucket Server. The password should be encrypted using public-key 
cryptography. Ggenerate a public/private key pair, encrypt the password 
with the public key, save it and the key's thumbprint in ''{0}'', then 
put the private key into the LocalComputer\My certificate store on every 
computer that will run these tests. 

123456789012345678901234567890123456789012345678901234567890123456789012
The Carbon module has functions for doing this. If you run the 
`init.ps1` script in the root of the repository, a copy of Carbon will 
be put in `packages\Carbon`. Then you can run these commands to generate
a key/pair and encrypt your password with it:

    > .\init.ps1
    > .\packages\Carbon\Import-Carbon.ps1
    > New-RsaKeyPair
    > Protect-String -String 'PASSWORD' -Certificate 'PUBLIC KEY PATH'
'@)
}

$config = Get-Content -Path $serverJsonPath -Raw | ConvertFrom-Json
if( -not $config )
{
    throw ('Test configuration file ''{0}'' is not valid JSON.' -f $serverJsonPath)
}

function Get-WhsBBServerTestProjectKey
{
    if( -not ($config | Get-Member -Name 'ProjectKey') -or -not $config.ProjectKey) 
    {
        throw ('ProjectKey is missing from ''{0}''.' -f $serverJsonPath)
    }

    $config.ProjectKey
}

function New-TestRepoName
{
    'BitbucketServerAutomationTest{0}' -f [IO.Path]::GetRandomFileName()
}

function New-WhsBBServerConnection
{
    foreach( $field in @('UserName','Password','DecryptionCertificateThumbprint') )
    {
        if( -not ($config | Get-Member -Name $field) -or -not $config.$field) 
        {
            throw ('{0} property is missing from ''{1}''.' -f $field, $serverJsonPath)
        }
    }

    $password = Unprotect-String -Thumbprint $config.DecryptionCertificateThumbprint -ProtectedString $config.Password -AsSecureString
    if( -not $password )
    {
        throw 'Unable to decrypt Password from ''{0}''.' -f $serverJsonPath
    }

    $credential = New-Object -TypeName 'Management.Automation.PSCredential' $config.UserName,$password
    New-BBServerConnection -Credential $credential -Uri 'https://stash.portal.webmd.com'
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
