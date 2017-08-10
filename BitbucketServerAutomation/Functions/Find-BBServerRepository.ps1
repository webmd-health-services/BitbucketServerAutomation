function Find-BBServerRepository
{
    param(
        [parameter(Mandatory=$true)]
        [Object]
        $Connection,
        # Wildcards supported.
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