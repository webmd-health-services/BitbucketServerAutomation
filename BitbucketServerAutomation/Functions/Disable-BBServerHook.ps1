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

function Disable-BBServerHook
{
    <#
    .SYNOPSIS
    Disables a hook in a repository.

    .DESCRIPTION
    The `Disable-BBServerHook` function sets the value of the `Enabled` property to `false` for a designated hook in a Bitbucket Server repository.
    
    If you pass a hook key that does not exist in the target repository, an error will be thrown.

    .EXAMPLE
    Disable-BBServerHook -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -HookKey 'com.atlassian.bitbucket.server.example-hook-key'

    Demonstrates how to disable a hook with key `com.atlassian.bitbucket.server.example-hook-key` in the `TestRepo` repository.
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

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the repository hook to disable.
        $HookKey
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $resourcePath = ('projects/{0}/repos/{1}/settings/hooks/{2}/enabled' -f $ProjectKey, $RepoName, $HookKey)
    
    Invoke-BBServerRestMethod -Connection $Connection -Method 'DELETE' -ApiName 'api' -ResourcePath $resourcePath
}
