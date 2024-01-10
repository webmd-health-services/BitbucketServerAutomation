

function Add-PSTypeName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='RepositoryInfo')]
        [Switch]
        $RepositoryInfo,

        [Parameter(Mandatory=$true,ParameterSetName='ProjectInfo')]
        [Switch]
        $ProjectInfo,

        [Parameter(Mandatory=$true,ParameterSetName='CommmitBuildStatusInfo')]
        [Switch]
        $CommitBuildStatusInfo
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $typeName = 'Atlassian.Bitbucket.Server.{0}' -f $PSCmdlet.ParameterSetName
        $InputObject.pstypenames.Add( $typeName )

        if( $ProjectInfo )
        {
            if( -not ($InputObject | Get-Member -Name 'description') )
            {
                $InputObject | Add-Member -MemberType NoteProperty -Name 'description' -Value ''
            }
        }

        $InputObject
    }
}