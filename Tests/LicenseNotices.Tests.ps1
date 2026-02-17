
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

Describe 'License Notices' {

    It 'should have a license notice in all files' {
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
            'whiskey.yml',
            'build.ps1',
            'appveyor.yml',
            'Dockerfile',
            'prism*.json'
        )

        $directoriesToExclude = @(
            '.github',
            '.output',
            '.vscode',
            'PSModules',
            'Tests'
        )

        [object[]]$filesMissingLicense =
            Get-ChildItem -Path $projectRoot -Exclude $directoriesToExclude |
            Get-ChildItem -Recurse -File -Exclude $filesToSkip |
            Where-Object { $name = $_.Name; -not ($filesToSkip | Where-Object { $name -like $_ }) } |
            Where-Object 'FullName' -NotLike '*\Functions\*' |
            ForEach-Object {
                $fileInfo = $_
                $file = Get-Content -Path $fileInfo.FullName -Raw

                if( (-not $file) -or ($file -notmatch $licenseNoticeRegex))
                {
                    $fileInfo.FullName
                }
            }

        $filesMissingLicense | Should -BeNullOrEmpty
    }
}
