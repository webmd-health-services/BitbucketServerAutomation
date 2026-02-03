
function Find-BBServerRepository
{
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        # Name of a Repository you wish to find. supports Wildcards.
        [String] $Name
    )
    Get-BBServerProject -Session $Session |
        ForEach-Object {
            return Get-BBServerRepository -Session $Session -ProjectKey $_.key |
                where-Object { $_.name -like $Name }
        }
}