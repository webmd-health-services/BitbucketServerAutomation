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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-BitbucketServerAutomationTest.ps1' -Resolve)

$projectKey = 'GBBSHOOK'
$repo = $null
$repoName = $null
$hookKey = 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Get-BBServerHook Tests'

function Init
{
    $script:repo = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey
    $script:repoName = $repo | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

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

function ThenShouldNotThrowErrors
{
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenShouldReturnAllHooks
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

function ThenShouldReturnSpecificHook
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

function ThenShouldNotReturnHooks
{
    param(
    )

    It 'should not return any hooks from the repository' {
        $script:getHooks | Should BeNullOrEmpty
    }
}

Describe 'Get-BBServerHook.when returning all hooks from a repository' {
    Init
    GivenARepository
    WhenGettingHooks
    ThenShouldNotThrowErrors
    ThenShouldReturnAllHooks
}

Describe 'Get-BBServerHook.when searching for a specific hook from a repository' {
    Init
    GivenARepository
    WhenGettingHooks -WithHookFilter $hookKey
    ThenShouldNotThrowErrors
    ThenShouldReturnSpecificHook $hookKey
}

Describe 'Get-BBServerHook.when searching for a hook that does not exist' {
    Init
    GivenARepository
    WhenGettingHooks -WithHookFilter 'hook.that.does.not.exist'
    ThenShouldNotThrowErrors
    ThenShouldNotReturnHooks
}
