
function New-BBServerConnection
{
    <#
    .SYNOPSIS
    Obsolete. Use New-BBServerSession instead.

    .DESCRIPTION
    Obsolete. Use New-BBServerSession instead.

    .EXAMPLE
    $session = New-BBServerSession -Credential (Get-Credential) -Url 'https://bitbucketserver.example.com/'

    Demonstrates how to create a session to Bitbucket Server using `New-BBServerSession` instead of
    `New-BBServerConnection`.
    #>
    [CmdletBinding()]
    param(
        # This function is obsolete. Use `New-BBServerSession` instead.
        [Parameter(Mandatory)]
        [pscredential] $Credential,

        # This function is obsolete. Use `New-BBServerSession` instead.
        [Parameter(Mandatory)]
        [Alias('Uri')]
        [uri] $Url,

        # This function is obsolete. Use `New-BBServerSession` instead.
        [String] $ApiVersion = '1.0'
    )

    Set-StrictMode -Version 'Latest'

    Write-Warning "The New-BBServerConnection function is obsolete. Use New-BBServerSession instead."

    New-BBServerSession @PSBoundParameters
}