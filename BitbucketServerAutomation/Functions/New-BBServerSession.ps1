
function New-BBServerSession
{
    <#
    .SYNOPSIS
    Creates an object that represents a session to an instance of Bitbucket Server.

    .DESCRIPTION
    The `New-BBServerSession` function creates an object that is used by most Bitbucket Server Automation functions to
    make requests to Bitbucket Server. You pass it credentials and the URL to the Bitbucket Server you want to make
    requests to. It returns an object that is then passed to additional functions that require it.

    .EXAMPLE
    $session = New-BBServerSession -Credential (Get-Credential) -Url 'https://bitbucketserver.example.com/'

    Demonstrates how to create a session.
    #>
    [CmdletBinding()]
    param(
        # The credential to use when making requests to Bitbucket Server. The credential is passed in plaintext, so make
        # sure your Bitbucket Server URL is HTTPS.
        [Parameter(Mandatory)]
        [pscredential] $Credential,

        # The URL to the Bitbucket Server to make requests to. The path to the API to use is appended to this URI. Typically,
        # you'll just pass the protocol and hostname, e.g. `https://bitbucket.example.com`.
        [Parameter(Mandatory)]
        [Uri] $Url,

        # The version of the API to use. The default is `1.0`.
        [String] $ApiVersion = '1.0'
    )

    Set-StrictMode -Version 'Latest'

    [pscustomobject]@{
                        'Credential' = $Credential;
                        'Url' = $Url;
                        # TODO: Remove Uri property in next major version.
                        'Uri' = $Url;
                        'ApiVersion' = '1.0';
                     }
}