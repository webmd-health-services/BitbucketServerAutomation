
function Enable-BBServerRepository
{
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Session to the instance of Bitbucket Server to make requests to. Use `New-BBServerSession` to create a
        # session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        [Parameter(Mandatory)]
        [String] $ProjectKey,

        # The repository to unarchive.
        [Parameter(Mandatory)]
        [String] $RepoName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Get-BBServerRepository -Session $Session -ProjectKey $ProjectKey -Name $RepoName
    if (-not $repo)
    {
        $msg = "Repository ""${RepoName}"" in project ""${ProjectKey}"" does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    if (-not $repo.archived)
    {
        return
    }

    $encProjectKey = [Uri]::EscapeDataString($ProjectKey)
    $encSlug = [Uri]::EscapeDataString($repo.slug)
    $resourcePath = "projects/${encProjectKey}/repos/${encSlug}"

    $body = @{ archived = $false }
    Invoke-BBServerRestMethod -Session $Session `
                              -Method Put `
                              -ApiName 'api' `
                              -ResourcePath $resourcePath `
                              -InputObject $body
}