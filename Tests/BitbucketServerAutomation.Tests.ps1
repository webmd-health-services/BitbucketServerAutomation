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

function Export-BitbucketServerModule
{
    if( (Get-Module -Name 'BitbucketServerAutomation') )
    {
        Remove-Module -Name 'BitbucketServerAutomation'
    }

}

Export-BitbucketServerModule

Describe 'BitbucketServerAutomation when getting imported via directory' {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\BitbucketServerAutomation' -Resolve)

    $errors = @()
    It 'should import the module' {
        Get-Module -Name 'BitbucketServerAutomation' -ErrorVariable 'errors' | Should Not BeNullOrEmpty
    }

    It 'should not write any errors' {
        $errors | Should BeNullOrEmpty
    }
}

Export-BitbucketServerModule
