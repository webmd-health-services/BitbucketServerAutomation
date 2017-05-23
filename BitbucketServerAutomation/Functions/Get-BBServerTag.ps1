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

function Get-BBServerTag 
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,    
  
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository's project.
        $ProjectKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository.
        $RepositoryKey

    )
  
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $result = Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $ProjectKey, $RepositoryKey)
    if (-not $result)
    {
        throw ("Unable to obtain BitBucket Server tags for project {0} in {1}." -f $ProjectKey, $RepositoryKey)
    }
    return $result
}

 
