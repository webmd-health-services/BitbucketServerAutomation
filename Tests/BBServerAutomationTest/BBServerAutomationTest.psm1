
function Get-WhsBBServerTestProjectKey
{
    'WHS'
}

function New-TestRepoName
{
    'BitbucketServerAutomationTest{0}' -f [IO.Path]::GetRandomFileName()
}

function New-WhsBBServerConnection
{
    $cred = Get-WhsSecret -Environment 'Dev' -Name 'svc-prod-lcsbitbucke' -AsCredential
    New-BBServerConnection -Credential $cred -Uri 'https://stash.portal.webmd.com'
}

function Remove-BBServerTestRepository
{
    Get-BBServerRepository -Connection $conn -ProjectKey $projectKey -Name 'BitbucketServerAutomationTest*' | Remove-BBServerRepository -Connection $conn 
}