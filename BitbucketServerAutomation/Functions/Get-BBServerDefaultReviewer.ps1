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

function Get-BBServerDefaultReviewer
{
    <#
    .SYNOPSIS
    Gets the default reviewer conditions for a project or repository.

    .DESCRIPTION
    The `Get-BBServerDefaultReviewer` function gets the default reviewer conditions that have been configured at either the project or repository level. When getting the default reviewer conditions for a repository, any default reviewer conditions inherited from the parent project will also be returned.

    .EXAMPLE
    Get-BBServerDefaultReviewer -Connection $conn -ProjectKey 'GBBSDR'

    Demonstrates getting all the default reviewer conditions that have been configured for the "GBBSDR" project.

    .EXAMPLE
    Get-BBServerDefaultReviewer -Connection $conn -ProjectKey 'GBBSDR' -RepositoryName 'Scripts'

    Demonstrates getting all the default reviewer conditions that have been configured for the "Scripts" repository, including any inherited conditions from its parent "GBBSDR" project.
    #>
    param(
        [Parameter(Mandatory)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting. Use `New-BBServerConnection` to create connection objects.
        $Connection,

        [Parameter(Mandatory)]
        [string]
        # The key/ID that identifies the project. This is *not* the project name.
        $ProjectKey,

        [string]
        # The name of a repository in the project.
        $RepositoryName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $resourcePath = 'projects/{0}/conditions' -f $ProjectKey
    if ($RepositoryName)
    {
        $resourcePath = 'projects/{0}/repos/{1}/conditions' -f $ProjectKey, $RepositoryName
    }

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'default-reviewers' -ResourcePath $resourcePath
}
