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

function Get-BBServerUser
{
    <#
    .SYNOPSIS
    Gets a Bitbucket Server user.

    .DESCRIPTION
    The `Get-BBServerUser` function gets users that exist in Bitbucket Server. By default all users are returned.

    To get specific users, pass a string representing a username, display name, or email address to the `Filter` parameter.

    .EXAMPLE
    Get-BBServerUser -Connection $BBConnection

    Demonstrates how to get all Bitbucket Server users.

    .EXAMPLE
    Get-BBServerUser -Connection $BBConnection -Filter 'email.com'

    Demonstrates how to get all Bitbucket Server users whose email address contains "email.com".
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [string]
        # Filter to use to find a specific user. This is passed to Bitbucket Server as-is. It searches a user's username, display name, and email address for the filter. If any field matches, that user is returned.
        $Filter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $requestQueryParameter = @{}
    if ($Filter)
    {
        $requestQueryParameter['Parameter'] = @{ 'filter' = $Filter }
    }

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath 'admin/users' -IsPaged @requestQueryParameter
}
