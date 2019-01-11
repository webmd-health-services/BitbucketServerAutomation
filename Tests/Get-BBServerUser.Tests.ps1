# Copyright 2018 WebMD Health Services
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

$BBConnection = New-BBServerTestConnection
$output = $null

function Init
{
    $Global:Error.Clear()
    $script:output = $null
}

function GivenUser
{
    param(
        [string[]]
        $Username
    )

    foreach($user in $Username)
    {
        if ($user -eq 'admin')
        {
            # 'admin' already exists from the local Bitbucket server setup in .\init.ps1
            continue
        }

        $requestQueryParameters = 'name={0}&password=hunter2&displayName={0}&emailAddress={0}@example.com' -f $user
        $requestQueryParameters = [Uri]::EscapeUriString($requestQueryParameters)

        Invoke-BBServerRestMethod -Connection $BBConnection -Method Post -ApiName 'api' -ResourcePath ('admin/users?{0}' -f $requestQueryParameters)
    }
}

function RemoveUser
{
    param(
        [string[]]
        $Username
    )

    foreach ($user in $Username)
    {
        Invoke-BBServerRestMethod -Connection $BBConnection -Method Delete -ApiName 'api' -ResourcePath ('admin/users?name={0}' -f $user)
    }
}

function ThenNoErrors
{
    It 'should not write any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenReturnedNothing
{
    It 'should not return any users' {
        $output | Should -BeNullOrEmpty
    }
}

function ThenReturnedUser
{
    param(
        [string[]]
        $Username
    )

    It 'should return the expected users' {
        $returnedUserCount = $output   | Measure-Object | Select-Object -ExpandProperty 'Count'
        $expectedUserCount = $Username | Measure-Object | Select-Object -ExpandProperty 'Count'

        $returnedUserCount | Should -Be $expectedUserCount

        foreach ($user in $Username)
        {
            $output.Name | Should -Contain $user
        }
    }
}

function WhenGettingUsers
{
    param(
        $WithFilter
    )

    $filterParam = @{}
    if ($WithFilter)
    {
        $filterParam['Filter'] = $WithFilter
    }

    $script:output = Get-BBServerUser -Connection $BBConnection @filterParam
}

Describe 'Get-BBServerUser.when getting all users' {
    try
    {
        Init
        GivenUser 'admin', 'thingOne', 'thingTwo'
        WhenGettingUsers
        ThenReturnedUser 'admin', 'thingOne', 'thingTwo'
        ThenNoErrors
    }
    finally
    {
        RemoveUser 'thingOne', 'thingTwo'
    }
}

Describe 'Get-BBServerUser.when given filter matching multiple users' {
    try
    {
        Init
        GivenUser 'admin', 'thingOne', 'thingTwo'
        WhenGettingUsers -WithFilter 'thing'
        ThenReturnedUser 'thingOne', 'thingTwo'
        ThenNoErrors
    }
    finally
    {
        RemoveUser 'thingOne', 'thingTwo'
    }
}

Describe 'Get-BBServerUser.when given filter matching no users' {
    try
    {
        Init
        GivenUser 'admin', 'thingOne', 'thingTwo'
        WhenGettingUsers -WithFilter 'samIAm'
        ThenReturnedNothing
        ThenNoErrors
    }
    finally
    {
        RemoveUser 'thingOne', 'thingTwo'
    }
}
