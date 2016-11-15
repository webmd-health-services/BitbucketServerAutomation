
function Export-BitbucketServerModule
{
    if( (Get-Module -Name 'BitbucketServerAutomation') )
    {
        Remove-Module -Name 'BitbucketServerAutomation'
    }

}

Export-BitbucketServerModule

Describe 'BitbucketServerAutomation when getting imported via directory' {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\BitbucketServerAutomation' -Resolve)

    It 'should import the module' {
        Get-Module -Name 'BitbucketServerAutomation' -ErrorVariable 'errors' | Should Not BeNullOrEmpty
    }

    It 'should not write any errors' {
        $errors | Should BeNullOrEmpty
    }
}

Export-BitbucketServerModule
