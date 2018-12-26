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

function Get-BBServerPullRequest
{
    <#
    .SYNOPSIS
    Gets pull requests

    .DESCRIPTION
    The `Get-BBServerPullRequest` function gets all pull requests in a Bitbucket Server instance. If you pass it an id, it will get just the pull request with that id.


    .EXAMPLE
    Get-BBServerPullRequest  -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -id $ID
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [string]
        # The id of the pull request to get, if this is not included the default will be to get all current pull requests
        $ID = "",

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName        
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $ResourcePath = ('projects/{0}/repos/{1}/pull-requests/{2}' -f $ProjectKey, $RepoName, $ID)
    
    return Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath $ResourcePath 
}
