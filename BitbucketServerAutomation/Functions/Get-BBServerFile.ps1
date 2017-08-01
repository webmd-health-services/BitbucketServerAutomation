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

function Get-BBServerFile
{
    <#
    .SYNOPSIS
    Gets a list of files from a repository.

    .DESCRIPTION
    The `Get-BBServerFile` function returns a list of all files in a Bitbucket Server repository.

    To get only files under part of a repository, pass its path to the `Path` parameter. The path should be relative to the root of the repository.
    
    To search for files, use the `Filter` parameter. Pass it the path to a specific file, or a wildcard pattern that matches multiple files. `Get-BBServerFile` uses PowerShell's `-like` operator to do the comparison.

    Note that when using the `Path` parameter, the Bitbucket Server API treats that path as if it were the root of the repository. Paths returns will not have `Path` at the beginning of the path. Filters that include `Path` will not match anything.

    .EXAMPLE
    Get-BBServerFile -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo'

    Demonstrates how to get a list of all the files `TestRepo` repository.

    .EXAMPLE
    Get-BBServerFile -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -Filter 'publish.ps1'

    Demonstrates how to get a specific file. In this case, only a file named `publish.ps1` in the root of the repository, is returned.

    .EXAMPLE
    Get-BBServerFile -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -Filter 'BitbucketServerAutomation/BitbucketServerAutomation.psd1'

    Demonstrates how to get a specific file. In this case, only a file `BitbucketServerAutomation/BitbucketServerAutomation.psd1` will be returned, if it exists.

    .EXAMPLE
    Get-BBServerFile -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -Filter '*.txt'

    Demonstrates how to get all files that match a wildcard. In this case, all files whose paths end in `.txt` will be returned. Uses PowerShell's `-like` operator.
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
        # The path where the search should start. By default the root of the repository is used so the whole repository is searched. Use this parameter to only search part of the repository.
        $Path,

        [string]
        # Only returns files whose paths match this filter. Wildcards are supported.
        $Filter
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $resourcePath = ('projects/{0}/repos/{1}/files/{2}' -f $ProjectKey, $RepoName, $Path)
    Invoke-BBServerRestMethod -Connection $Connection -Method 'GET' -ApiName 'api' -ResourcePath ('{0}?limit={1}' -f $resourcePath, [int16]::MaxValue) | 
        Select-Object -ExpandProperty 'values' |
        Where-Object {
            if( $Filter )
            {
                return $_ -like $Filter
            }
            return $true
        }
}
