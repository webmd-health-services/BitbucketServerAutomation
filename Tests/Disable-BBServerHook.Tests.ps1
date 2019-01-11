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

$projectKey = 'DBBSHOOK'
$projectName = 
$repoName = $null
$hookKey = 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook'
$bbConnection = New-BBServerTestConnection -ProjectKey $projectKey -ProjectName 'Disable-BBServerHook Tests'

function Init
{
    $script:repoName = New-BBServerTestRepository -Connection $bbConnection -ProjectKey $projectKey | Select-Object -ExpandProperty 'name'

    # $DebugPreference = 'Continue'
    Write-Debug -Message ('Project: {0}' -f $projectKey)
    Write-Debug -message ('Repository: {0}' -f $repoName)
}

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
    [CmdletBinding()]
    param(
        [string]
        $WithHook
    )

    $Global:Error.Clear()

    Disable-BBServerHook -Connection $bbConnection -ProjectKey $projectKey -RepoName $repoName -HookKey $WithHook
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
    Init
    GivenARepository
    WhenDisablingRepositoryHook $hookKey
    ThenShouldNotThrowErrors
    ThenHookShouldBeDisabled $hookKey
}

Describe 'Disable-BBServerHook.when disabling a hook that is already disabled' {
    Init
    GivenARepository
    GivenHookIsDisabled $hookKey
    WhenDisablingRepositoryHook $hookKey
    ThenShouldNotThrowErrors
    ThenHookShouldBeDisabled $hookKey
}

Describe 'Disable-BBServerHook.when disabling a hook that does not exist' {
    Init
    GivenARepository
    WhenDisablingRepositoryHook 'not.a.valid.hook.key' -ErrorAction SilentlyContinue
    ThenShouldThrowError 'An error occurred while processing the request'
}
