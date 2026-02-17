
function Invoke-BBServerRestMethod
{
    <#
    .SYNOPSIS
    Calls a method in the Bitbucket Server REST API.

    .DESCRIPTION
    The `Invoke-BBServerRestMethod` function calls a method on the Bitbucket Server REST API. You pass it a Session
    object (returned from `New-BBServerSession`), the HTTP method to use, the name of API (via the `ApiName` parametr),
    the name/path of the resource via the `ResourcePath` parameter, and a hashtable/object/psobject via the
    `InputObject` parameter representing the data to send in the body of the request. The data is converted to JSON and
    sent in the body of the request.

    A Bitbucket Server URL has the form `https://example.com/rest/API_NAME/API_VERSION/RESOURCE_PATH`. `API_VERSION` is
    taken from the session passed to the `Session` parameter. The `API_NAME` path should be passed to the `ApiName`
    paramter. The `RESOURCE_PATH` path should be passed to the `ResourcePath` parameter. The base URL is taken from the
    `Url` property of the session object passed to the `Session` parameter. If you want the raw text content from the
    API back instead of an object, use the `-Raw` switch.

    .EXAMPLE
    $body | Invoke-BBServerRestMethod -Session $Session -Method Post -ApiName 'build-status' -ResourcePath ('commits/{0}' -f $commitID)

    Demonstrates how to call the /build-status API's `/commits/COMMIT_ID` resource. Body is a hashtable that looks like
    this:

        $body = @{
                    state = 'INPROGRESS';
                    key = 'MY_BUILD_KEY';
                    name = 'MY_BUILD_NAME';
                    url = 'MY_BUILD_URL';
                    description = 'MY_BUILD_DESCRIPTION';
                 }

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Alias('Connection')]
        [Object] $Session,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method,

        # The name of the API being invoked, e.g. `projects`, `build-status`, etc. If the endpoint URL is
        # `http://example.com/rest/build-status/1.0/commits`, the API name is between the `rest` and API version, which
        # in this example is `build-status`.
        [Parameter(Mandatory ,ParameterSetName='SimpleUrl')]
        [String] $ApiName,

        # The path to the resource to use. If the endpoint URL `http://example.com/rest/build-status/1.0/commits`, the
        # ResourcePath is everything after the API version. In this case, the resource path is `commits`.
        [Parameter(Mandatory, ParameterSetName='SimpleUrl')]
        [String] $ResourcePath,

        [Parameter(Mandatory, ParameterSetName='FullPath')]
        [String] $Path,

        [Parameter(ValueFromPipeline)]
        [Object] $InputObject,

        # Hashtable representing the request query parameters to include when calling the API resource.
        [hashtable] $Parameter,

        [switch] $IsPaged,

        [String] $ContentType = 'application/json',

        # Return the raw response content, not a JSON object.
        [switch] $Raw
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'SimpleUrl' )
    {
        $Path = 'rest/{0}/{1}/{2}' -f $ApiName.Trim('/'),$Session.ApiVersion.Trim('/'),$ResourcePath.Trim('/')
    }

    if ($Parameter)
    {
        $requestQueryParameter = ''
        foreach ($key in $Parameter.Keys)
        {
            $requestQueryParameter += '&{0}={1}' -f [Uri]::EscapeDataString($key), [Uri]::EscapeDataString($Parameter[$key])
        }

        $requestQueryParameter = $requestQueryParameter.TrimStart('&')
        $Path = '{0}?{1}' -f $Path, $requestQueryParameter
    }

    [Uri] $sessionUrl = $Session | Select-Object -Expand 'Url' -ErrorAction Ignore
    if (-not $sessionUrl)
    {
        $sessionUrl = $Session | Select-Object -Expand 'Uri' -ErrorAction Ignore

        if (-not $sessionUrl)
        {
            $msg = 'Unable to make a request to Bitbucket Server because the session object is missing a `Url` ' +
                   'property. Did you use `New-BBServerSession` to create a session?'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }
    }

    $url = [Uri]::New($sessionUrl, $Path)

    $bodyParam = @{ }
    if( $InputObject )
    {
        $bodyParam['Body'] = $InputObject | ConvertTo-Json -Depth 100
    }

    #$DebugPreference = 'Continue'
    Write-Verbose -Message ('{0} {1}' -f $Method.ToString().ToUpperInvariant(), $url.AbsoluteUri)
    if( $bodyParam['Body'] )
    {
        Write-Verbose -Message $bodyParam['Body']
    }

    $credential = $Session.Credential
    $credential = '{0}:{1}' -f $credential.UserName,$credential.GetNetworkCredential().Password

    $authHeaderValue = 'Basic {0}' -f [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes($credential) )
    $headers = @{
        'Authorization' = $authHeaderValue
        'X-Atlassian-Token' = 'no-check'
    }

    try
    {
        if( $IsPaged )
        {
            $nextPageStart = 0
            $isLastPage = $false

            while( $isLastPage -eq $false )
            {
                if ($Path -match '\?')
                {
                    $queryStringSeparator = '&'
                }
                else
                {
                    $queryStringSeparator = '?'
                }

                $urlPagedPath = ('{0}{1}limit={2}&start={3}' -f $Path, $queryStringSeparator, [int16]::MaxValue, $nextPageStart)
                $url = [Uri]::New($sessionUrl, $urlPagedPath)

                $getStream = Invoke-RestMethod -Method $Method `
                                               -Uri $url `
                                               -Headers $headers `
                                               -ContentType 'application/json' `
                                               @bodyParam `
                                               -ErrorVariable 'errors'
                if( $getStream.isLastPage -eq $false )
                {
                    $nextPageStart = $getStream.nextPageStart
                }
                else
                {
                    $isLastPage = $true
                }

                $getStream | Select-Object -ExpandProperty 'values'
            }
        }
        else
        {

            $cmdName = 'Invoke-RestMethod'
            if ($Raw)
            {
                $cmdName = 'Invoke-WebRequest'
            }

            $invokeArgs = @{}
            if ((Get-Command -Name $cmdName -ParameterName 'UseBasicParsing' -ErrorAction Ignore))
            {
                $invokeArgs['UseBasicParsing'] = $true
            }

            if ($Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get -or $PSCmdlet.ShouldProcess($url,$method))
            {
                $response = & $cmdName -Method $Method `
                                       -Uri $url `
                                       -Headers $headers `
                                       -ContentType $ContentType `
                                       @bodyParam `
                                       @invokeArgs `
                                       -ErrorVariable 'errors'
                if ($Raw)
                {
                    $response.Content | Write-Output
                }
                else
                {
                    $response | Write-Output
                }

            }
        }
    }
    catch
    {
        $responseContent = $null
        $exceptionType = $_.Exception.GetType().FullName

        if ($exceptionType -eq 'System.Net.WebException')
        {
            $response = $_.Exception.Response
            if ($response -and $response.ContentType -like '*json*')
            {
                $reader = New-Object 'IO.StreamReader' $response.GetResponseStream()
                $json = $reader.ReadToEnd()
                if ($json)
                {
                    $responseContent = $json | ConvertFrom-Json
                }
                $reader.Dispose()
            }
        }
        elseif (($exceptionType -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -and $_.ErrorDetails)
        {
            try
            {
                $responseContent = $_.ErrorDetails | ConvertFrom-Json
            }
            catch
            {
                $responseContent = $_.ErrorDetails
            }
        }

        for( $idx = 0; $idx -lt $errors.Count; ++$idx )
        {
            if( $Global:Error.Count -gt 0 )
            {
                $Global:Error.RemoveAt(0)
            }
        }

        if( -not $responseContent )
        {
            Write-Error -ErrorRecord $_ -ErrorAction $ErrorActionPreference
            return
        }

        foreach( $item in $responseContent.errors )
        {
            $message = $item.message
            if( $item.context )
            {
                $message ='{0} [context: {1}]' -f $message,$item.context
            }
            if( $item.exceptionName )
            {
                $message = '{0}: {1}' -f $item.exceptionName,$message
            }

            Write-Error -Message $message -ErrorAction $ErrorActionPreference
        }
    }
}