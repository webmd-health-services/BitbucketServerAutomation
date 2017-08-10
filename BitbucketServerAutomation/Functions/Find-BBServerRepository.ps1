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
    $repositoryList = @()
    Get-BBServerProject -Connection $Connection |
        ForEach-Object {
        $repositoryList += Get-BBServerRepository -Connection $Connection -ProjectKey $_.key| Where-Object { $_.name -like $Name }
    }
    return $repositoryList
}