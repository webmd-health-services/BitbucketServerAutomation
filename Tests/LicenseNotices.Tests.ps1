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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

Describe 'License Notices' {

    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    $licenseFilePath = Join-Path -Path $projectRoot -ChildPath 'LICENSE' -Resolve

    $noticeLines = & {

       'Copyright\ 20\d{2}(?:\ ?-\ ?20\d{2})?\ WebMD Health Services'

        Get-Content -Path $licenseFilePath -Tail 11 |
        ForEach-Object {
            $line = $_.Trim()
            if ($line)
            {
                [regex]::Escape($line)
            }
        }
    }

    $licenseNoticeRegex = '(?s){0}' -f ($noticeLines -join ('.+'))

    # $DebugPreference = 'Continue'
    $licenseNoticeRegex | Write-Debug

    $filesToSkip = @(
        '.*',
        '*.md',
        'LICENSE',
        'NOTICE',
        'pester.xml',
        'whiskey.yml'
    )

    $directoriesToExclude = @(
        '.output',
        '.whiskey',
        '.vscode',
        'PSModules'
    )

    [object[]]$filesMissingLicense = Get-ChildItem -Path $projectRoot -Exclude $directoriesToExclude |
        Get-ChildItem -Recurse -File -Exclude $filesToSkip |
        Where-Object { $name = $_.Name; -not ($filesToSkip | Where-Object { $name -like $_ }) } |
        ForEach-Object {
            $fileInfo = $_
            $file = Get-Content -Path $fileInfo.FullName -Raw

            if( (-not $file) -or ($file -notmatch $licenseNoticeRegex))
            {
                $fileInfo.FullName
            }
        }

    It 'should have a license notice in all files' {
        $filesMissingLicense | Should -BeNullOrEmpty
    }
}
