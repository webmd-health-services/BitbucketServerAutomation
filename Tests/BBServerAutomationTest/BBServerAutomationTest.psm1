
function Get-WhsBBServerTestProjectKey
{
    'WHS'
}

function New-WhsBBServerConnection
{
    $cred = Get-WhsSecret -Environment 'Dev' -Name 'svc-prod-lcsbitbucke' -AsCredential
    New-BBServerConnection -Credential $cred -Uri 'https://stash.portal.webmd.com'
}