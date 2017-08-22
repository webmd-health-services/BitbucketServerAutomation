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

$projectKey = 'GBBSHOOK'
$repoName = 'RepositoryWithHook'
$hookKey = 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerHook Tests'

New-BBServerRepository -Connection $bbConnection -ProjectKey $projectKey -Name $repoName -ErrorAction Ignore | Out-Null

function GivenARepository
{
    param(
    )
}

function WhenGettingHooks
{
    param(
        [string]
        $WithHookFilter
    )

    $Global:Error.Clear()
    
    $script:getHooks = @(Get-BBServerHook -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName $WithHookFilter)
}

function ShouldNotThrowErrors
{
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ShouldReturnAllHooks
{
    param(
    )

    It 'should return all of the hooks from the repository' {
        $script:getHooks.Count -gt 0
    }

    It 'should contain the default hook key that is bundled with Bitbucket Server' {
        $script:getHooks | Where-Object { $_.details.key -eq $hookKey } | Should Not BeNullOrEmpty
    }
}

function ShouldReturnSpecificHook
{
    param(
        [string]
        $HookKeyFilter
    )

    It 'should return exactly 1 hook from the repository' {
        $script:getHooks.Count -eq 1
    }

    It ('should return the hook key: ''{0}''' -f $HookKeyFilter) {
        $script:getHooks | Where-Object { $_.details.key -eq $HookKeyFilter } | Should Not BeNullOrEmpty
    }
}

function ShouldNotReturnHooks
{
    param(
    )

    It 'should not return any hooks from the repository' {
        $script:getHooks | Should BeNullOrEmpty
    }
}

Describe 'Get-BBServerHook.when returning all hooks from a repository' {
    GivenARepository
    WhenGettingHooks
    ShouldNotThrowErrors
    ShouldReturnAllHooks
}

Describe 'Get-BBServerHook.when searching for a specific hook from a repository' {
    GivenARepository
    WhenGettingHooks -WithHookFilter $hookKey
    ShouldNotThrowErrors
    ShouldReturnSpecificHook $hookKey
}

Describe 'Get-BBServerHook.when searching for a hook that does not exist' {
    GivenARepository
    WhenGettingHooks -WithHookFilter 'hook.that.does.not.exist'
    ShouldNotThrowErrors
    ShouldNotReturnHooks
}
