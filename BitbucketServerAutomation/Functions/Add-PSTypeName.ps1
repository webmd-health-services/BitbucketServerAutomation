
function Add-PSTypeName
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $InputObject,

        [Switch]
        $RepositoryInfo,

        [Switch]
        $ProjectInfo
    )

    process
    {
        if( $RepositoryInfo )
        {
            $InputObject.pstypenames.Add( 'Atlassian.Bitbucket.Server.RepositoryInfo' )
        }

        if( $ProjectInfo )
        {
            $InputObject.pstypenames.Add( 'Atlassian.Bitbucket.Server.ProjectInfo' )
            if( -not ($InputObject | Get-Member -Name 'description') )
            {
                $InputObject | Add-Member -MemberType NoteProperty -Name 'description' -Value ''
            }
        }

        $InputObject
    }
}