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

function Get-BBServerHook
{
    <#
    .SYNOPSIS
    Gets a list of hooks from a repository.

    .DESCRIPTION
    The `Get-BBServerHook` function returns a list of all hooks in a Bitbucket Server repository.
    
    If you pass a hook key, the function will only return the information for the named hook and will return nothing if no hooks are found that match the search criteria. Wildcards are allowed for hook keys.

    .EXAMPLE
    Get-BBServerHook -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo'

    Demonstrates how to get the properties of all hooks in the `TestRepo` repository.

    .EXAMPLE
    Get-BBServerHook -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -HookKey 'com.atlassian.bitbucket.server.example-hook-key'

    Demonstrates how to get the properties of the 'com.atlassian.bitbucket.server.example-hook-key' hook in the `TestRepo` repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,

        [string]
        # The name of the hook to search for.
        $HookKey
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $resourcePath = ('projects/{0}/repos/{1}/settings/hooks' -f $ProjectKey, $RepoName)
    
    $getHooks = Invoke-BBServerRestMethod -Connection $Connection -Method 'GET' -ApiName 'api' -ResourcePath $resourcePath -IsPaged
    
    if( $HookKey )
    {
        return $getHooks | Where-Object { $_.details.key -like $HookKey }
    }
    else
    {
        return $getHooks
    }
}
