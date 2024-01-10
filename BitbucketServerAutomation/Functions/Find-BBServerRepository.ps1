
function Find-BBServerRepository
{
    param(
        [parameter(Mandatory=$true)]
        [Object]
        $Connection,

        # Name of a Repository you wish to find. supports Wildcards.
        [String]
        $Name
    )
    Get-BBServerProject -Connection $Connection |
        ForEach-Object {
            return Get-BBServerRepository -Connection $Connection -ProjectKey $_.key |
                where-Object { $_.name -like $Name }
        }
}