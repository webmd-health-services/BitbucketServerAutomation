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

function Invoke-BBServerPullRequestMerge
{
    param(        
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,
        [Parameter(Mandatory=$true)]
        [string]
        $ProjectKey,
        [Parameter(Mandatory=$true)]
        [string]
        $RepoName,
        [Parameter(Mandatory=$true)]
        [string]
        $id,
        [Parameter(Mandatory=$true)]
        [string]
        $version
    )
        $body = @{
            version = $version;
        }
        $resourcePath = ('projects/{0}/repos/{1}/pull-requests/{2}/merge' -f $ProjectKey, $RepoName, $id )

        return $body | Invoke-BBServerRestMethod -Connection $Connection -Method 'POST' -ApiName 'api' -ResourcePath $resourcePath
}
