
Set-StrictMode -Version 'Latest'
#Requires -Version 4

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

function Assert-StatusUpdatedTo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateSet('InProgress','Successful','Failed')]
        $ExpectedStatus,

        [object]
        $WithConnection,

        [string]
        $WithDescription = '',

        [hashtable]
        $FromEnvironment,

        [Switch]
        $ForJenkins,

        [Switch]
        $ForTeamCity
    )

    It 'should post status to Bitbucker Server' {
        $expectedCommitID = $FromEnvironment.CommitID
        $expectedKey = $FromEnvironment.Key
        $expectedName = $FromEnvironment.Name
        $expectedJobUrl = $FromEnvironment.Url

        Assert-MockCalled -CommandName 'Invoke-RestMethod' -ModuleName 'BitbucketServerAutomation' -Times 1 -ParameterFilter {
            $DebugPreference = 'Continue'

            Write-Debug -Message ('Body           actual    {0}' -f $Body)

            $data = $Body | ConvertFrom-Json

            $expectedUri = [uri]'{0}/rest/build-status/1.0/commits/{1}' -f $WithConnection.Uri.ToString().Trim("/"),$expectedCommitID
            Write-Debug -Message ('Uri            expected  {0}' -f $expectedUri)
            Write-Debug -Message ('               actual    {0}' -f $Uri)

        
            $expectedMethod = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
            Write-Debug -Message ('Method         expected  {0}' -f $expectedMethod)
            Write-Debug -Message ('               actual    {0}' -f $Method)
                                                               
            $expectedContentType = 'application/json'
            Write-Debug -Message ('ContentType    expected  {0}' -f $expectedContentType)
            Write-Debug -Message ('               actual    {0}' -f $ContentType)

            $ExpectedStatus = $ExpectedStatus.ToUpperInvariant()
            Write-Debug -Message ('State          expected  {0}' -f $ExpectedStatus)
            Write-Debug -Message ('               actual    {0}' -f $data.State)

            Write-Debug -Message ('Key            expected  {0}' -f $expectedKey)
            Write-Debug -Message ('               actual    {0}' -f $data.Key)

            Write-Debug -Message ('Name           expected  {0}' -f $expectedName)
            Write-Debug -Message ('               actual    {0}' -f $data.Name)

            Write-Debug -Message ('JobUrl         expected  {0}' -f $expectedJobUrl)
            Write-Debug -Message ('               actual    {0}' -f $data.Url)

            Write-Debug -Message ('Description    expected  {0}' -f $WithDescription)
            Write-Debug -Message ('               actual    {0}' -f $data.Description)

            if( -not $Headers.ContainsKey('Authorization') )
            {
                Write-Debug -Message ('Authorization header missing.')
                return $false
            }

            $authHeader = $Headers['Authorization']
            if( $authHeader -notmatch '^Basic\ ([^ ]+)$' )
            {
                Write-Debug -Message ('Authorization invalid.')
                return $false
            }

            Write-Debug -Message ('Authorization  actual    {0}' -f $authHeader)
            $username,$password = (ConvertFrom-Base64 -Value $Matches[1] -Encoding ([Text.Encoding]::UTF8)) -split ':'

            $expectedUsername =  $WithConnection.Credential.UserName
            Write-Debug -Message ('Username       expected  {0}' -f $expectedUsername)
            Write-Debug -Message ('               actual    {0}' -f $username)

            $expectedPassword = $WithConnection.Credential.GetNetworkCredential().Password
            Write-Debug -Message ('Password       expected  {0}' -f $expectedPassword)
            Write-Debug -Message ('               actual    {0}' -f $password)


            $Uri -eq $expectedUri -and `
            $Method -eq $ExpectedMethod -and `
            $ContentType -eq $expectedContentType -and `
            $username -eq $expectedUsername -and `
            $password -eq $expectedPassword -and `
            $data.State -ceq $ExpectedStatus -and `
            $data.Key -eq $expectedKey -and `
            $data.Name -eq $expectedName -and `
            $data.Url -eq $expectedJobUrl -and `
            $data.Description -eq $WithDescription
        }
    }
}

function New-MockBBServer
{
    Mock -CommandName 'Invoke-RestMethod' -Verifiable -ModuleName 'BitbucketServerAutomation'
    New-BBServerConnection -Uri 'https://example.com' -Credential (New-Credential -UserName 'fubar' -Password 'snafu')
}

function New-MockJenkinsBuild
{
    $buildEnv = @{
                    CommitID = 'abcdef01234567890';
                    Key = 'my_build_tag';
                    Url = 'https://example.com/my_build_tag';
                    Name = 'my_build';
                 }
    Mock -CommandName 'Test-Path' -ModuleName 'BitbucketServerAutomation' -MockWith { $true } -ParameterFilter { $Path -eq 'env:GIT_COMMIT' }
    Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.CommitID } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:GIT_COMMIT' }
    Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.Key } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:BUILD_TAG' }
    Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.Url } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:BUILD_URL' }
    Mock -CommandName 'Get-Item' -ModuleName 'BitbucketServerAutomation' -MockWith { [pscustomobject]@{ Value = $buildEnv.Name } }.GetNewClosure() -ParameterFilter { $Path -eq 'env:JOB_NAME' }
    return $buildEnv
}

Describe 'when a build starts under Jenkins' {
    $conn = New-MockBBServer
    $env = New-MockJenkinsBuild

    Set-BBServerCommitBuildStatus -Connection $conn -Status InProgress

    Assert-StatusUpdatedTo InProgress -WithConnection $conn -FromEnvironment $env
}