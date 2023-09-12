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

function Get-BBServerFileContent
{
    <#
    .SYNOPSIS
    Gets the raw content of a file in a repository.

    .DESCRIPTION
    The `Get-BBServerFileContent` function gets the raw content of a file from a repository. Pass the connection to the
    Bitbucket Server to the `Connection` object. Pass the project key of the repository to the `ProjectKey` parameter.
    Pass the repository name to the `RepoName` parameter. Pass the path to the file in the repository to the `Path`
    parameter. The raw content of the file is returned.

    To retrieve the value of the file at a specific commit, pass the commitish identifier (a tag, hash, branch name,
    etc.) to the `Commitish` parameter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        [Object] $Connection,

        [Parameter(Mandatory)]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        [String] $ProjectKey,

        [Parameter(Mandatory)]
        # The name of a specific repository.
        [String] $RepoName,

        [Parameter(Mandatory)]
        # The path of the file in the repository. Use forward-slashes for directory separators.
        [String] $Path,

        # The commit at which to get the file's contents.
        [String] $Commitish
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Path = "projects/$($ProjectKey)/repos/$($RepoName)/raw/$($Path)"

    $parameter = @{}
    if( $Commitish )
    {
        $parameter['at'] = $Commitish
    }

    Invoke-BBServerRestMethod -Connection $Connection `
                              -Method Get `
                              -ApiName 'api' `
                              -ResourcePath $Path `
                              -Parameter $parameter `
                              -Raw
}