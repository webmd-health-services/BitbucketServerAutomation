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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$projectKey = 'DBBSHOOK'
$repoName = 'RepositoryWithHook'
$hookKey = 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Disable-BBServerHook Tests'

New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null

function GivenARepository
{
    param(
    )

    Enable-BBServerHook -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -HookKey $hookKey
}

function GivenHookIsDisabled
{
    param(
        [string]
        $WithHook
    )

    Disable-BBServerHook -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -HookKey $hookKey
}

function WhenDisablingRepositoryHook
{
    param(
        [string]
        $WithHook
    )

    $Global:Error.Clear()
    
    Disable-BBServerHook -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -HookKey $WithHook -ErrorAction SilentlyContinue
}

function ThenShouldNotThrowErrors
{
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenShouldThrowError
{
    param(
        [string]
        $Error
    )

    It ('should throw error: ''{0}''' -f $Error) {
        $Global:Error | Should Match $Error
    }
}

function ThenHookShouldBeDisabled
{
    param(
        [string]
        $WithHook
    )

    It ('''{0}'' should be enabled in the repository' -f $WithHook) {
        (Get-BBServerHook -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -HookKey $WithHook).enabled | Should Be $false
    }
}

Describe 'Disable-BBServerHook.when disabling a hook in a repository' {
    GivenARepository
    WhenDisablingRepositoryHook $hookKey
    ThenShouldNotThrowErrors
    ThenHookShouldBeDisabled $hookKey
}

Describe 'Disable-BBServerHook.when disabling a hook that is already disabled' {
    GivenARepository
    GivenHookIsDisabled $hookKey
    WhenDisablingRepositoryHook $hookKey
    ThenShouldNotThrowErrors
    ThenHookShouldBeDisabled $hookKey
}

Describe 'Disable-BBServerHook.when disabling a hook that does not exist' {
    GivenARepository
    WhenDisablingRepositoryHook 'not.a.valid.hook.key'
    ThenShouldThrowError 'An error occurred while processing the request'
}
