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

function Remove-BBServerTag 
{
    <#
    .SYNOPSIS
    Removes a tag from a repository in Bitbucket Server.

    .DESCRIPTION
    The `Remove-BBServerTag` function removes a git tag associated with a particular repository in Bitbucket Server. If the requested tag does not exist on the server, an error is thrown.

    .EXAMPLE
    Remove-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName -TagName $tag.displayId

    Demonstrates how to remove the git tag for the associated repo
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,    
  
        [Parameter(Mandatory=$true)]
        [String]
        # The key of the repository's project.
        $ProjectKey,
 
        [Parameter(Mandatory=$true)]
        [String]
        # The key of the repository.
        $RepositoryKey,

        [Parameter(Mandatory=$true)]
        [String]
        # The name of the tag to be deleted.
        $TagName
    )
  
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-BBServerRestMethod -Connection $Connection -Method DELETE -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags/{2}' -f $ProjectKey, $RepositoryKey, $TagName) 
}

 
