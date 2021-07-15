# Copyright 2016 - 2018 WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Invoke-BBServerRestMethod
{
    <#
    .SYNOPSIS
    Calls a method in the Bitbucket Server REST API.

    .DESCRIPTION
    The `Invoke-BBServerRestMethod` function calls a method on the Bitbucket Server REST API. You pass it a Connection object (returned from `New-BBServerConnection`), the HTTP method to use, the name of API (via the `ApiName` parametr), the name/path of the resource via the `ResourcePath` parameter, and a hashtable/object/psobject via the `InputObject` parameter representing the data to send in the body of the request. The data is converted to JSON and sent in the body of the request.

    A Bitbucket Server URI has the form `https://example.com/rest/API_NAME/API_VERSION/RESOURCE_PATH`. `API_VERSION` is taken from the connection object passed to the `Connection` parameter. The `API_NAME` path should be passed to the `ApiName` paramter. The `RESOURCE_PATH` path should be passed to the `ResourcePath` parameter. The base URI is taken from the `Uri` property of the connection object passed to the `Connection` parameter.

    .EXAMPLE
    $body | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'build-status' -ResourcePath ('commits/{0}' -f $commitID)

    Demonstrates how to call the /build-status API's `/commits/COMMIT_ID` resource. Body is a hashtable that looks like this:

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
        [Parameter(Mandatory=$true)]
        [object]
        # The connection to use to invoke the REST method.
        $Connection,

        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method,

        [Parameter(Mandatory,ParameterSetName='SimpleUri')]
        [string]
        # The name of the API being invoked, e.g. `projects`, `build-status`, etc. If the endpoint URI is `http://example.com/rest/build-status/1.0/commits`, the API name is between the `rest` and API version, which in this example is `build-status`.
        $ApiName,

        [Parameter(Mandatory,ParameterSetName='SimpleUri')]
        [string]
        # The path to the resource to use. If the endpoint URI `http://example.com/rest/build-status/1.0/commits`, the ResourcePath is everything after the API version. In this case, the resource path is `commits`.
        $ResourcePath,

        [Parameter(Mandatory,ParameterSetName='FullPath')]
        [String]$Path,

        [Parameter(ValueFromPipeline=$true)]
        [object]
        $InputObject,

        [hashtable]
        # Hashtable representing the request query parameters to include when calling the API resource.
        $Parameter,

        [switch]
        $IsPaged
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'SimpleUri' )
    {
        $Path = 'rest/{0}/{1}/{2}' -f $ApiName.Trim('/'),$Connection.ApiVersion.Trim('/'),$ResourcePath.Trim('/')
    }

    if ($Parameter)
    {
        $requestQueryParameter = ''
        foreach ($key in $Parameter.Keys)
        {
            $requestQueryParameter += '&{0}={1}' -f [uri]::EscapeDataString($key), [uri]::EscapeDataString($Parameter[$key])
        }

        $requestQueryParameter = $requestQueryParameter.TrimStart('&')
        $Path = '{0}?{1}' -f $Path, $requestQueryParameter
    }

    $uri = New-Object 'Uri' -ArgumentList $Connection.Uri,$Path

    $bodyParam = @{ }
    if( $InputObject )
    {
        $bodyParam['Body'] = $InputObject | ConvertTo-Json -Depth 100
    }

    #$DebugPreference = 'Continue'
    Write-Debug -Message ('{0} {1}' -f $Method.ToString().ToUpperInvariant(), $uri)
    if( $bodyParam['Body'] )
    {
        Write-Debug -Message $bodyParam['Body']
    }

    $credential = $Connection.Credential
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

                $uriPagedPath = ('{0}{1}limit={2}&start={3}' -f $Path, $queryStringSeparator, [int16]::MaxValue, $nextPageStart)
                $uri = New-Object 'Uri' -ArgumentList $Connection.Uri,$uriPagedPath

                $getStream = Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' @bodyParam -ErrorVariable 'errors'
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
            if( $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get -or $PSCmdlet.ShouldProcess($uri,$method) )
            {
                Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' @bodyParam -ErrorVariable 'errors'
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
            if( $response )
            {
                $reader = New-Object 'IO.StreamReader' $response.GetResponseStream()
                $responseContent = $reader.ReadToEnd() | ConvertFrom-Json
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
