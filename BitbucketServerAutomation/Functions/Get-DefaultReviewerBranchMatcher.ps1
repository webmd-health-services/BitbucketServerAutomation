
function Get-DefaultReviewerBranchMatcher
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        # The name of the parameter that contains the branch matching type. Used for writing warning and errors messages.
        $TypeParameterName,

        [Parameter(Mandatory)]
        [string]
        # The name of the parameter that contains the branch matching value. Used for writing warning and errors messages.
        $ValueParameterName,

        [Parameter(Mandatory)]
        [ValidateSet('Any', 'Name', 'Pattern', 'Model')]
        # The type of matching for the branch.
        $Type,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        # Specifies the value or pattern to match a branch.
        $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $branchingModelCategories = @('Feature', 'Bugfix', 'Hotfix', 'Release')
    $branchingModelBranches = @('Development', 'Production')
    $specificBranchTypes = @('Name', 'Pattern', 'Model')

    if ($Type -in $specificBranchTypes -and -not $Value)
    {
        Write-Error -Message ('"{0}" cannot be empty if "{1}" is one of "{2}"' -f $ValueParameterName, $TypeParameterName, ($specificBranchTypes -join ', ')) -ErrorAction $ErrorActionPreference
        return
    }

    if ($Type -eq 'Any')
    {
        if ($Value)
        {
            Write-Warning -Message ('"{0}" is "Any", ignoring "{1}" parameter.' -f $TypeParameterName, $ValueParameterName)
        }

        $matcherId = $matcherDisplayId = 'ANY_REF_MATCHER_ID'
        $matcherTypeId = 'ANY_REF'
        $matcherTypeName = 'Any branch'
    }
    elseif ($Type -eq 'Name')
    {
        $matcherId = $matcherDisplayId = $Value
        $matcherTypeId = 'BRANCH'
        $matcherTypeName = 'Branch'
    }
    elseif ($Type -eq 'Pattern')
    {
        $matcherId = $matcherDisplayId = $Value
        $matcherTypeId = 'PATTERN'
        $matcherTypeName = 'Pattern'
    }
    elseif ($Type -eq 'Model')
    {
        if ($Value -notin $branchingModelCategories -and $Value -notin $branchingModelBranches)
        {
            Write-Error -Message ('When "{0}" is "Model", parameter "{1}" must be one of "{2}, {3}"' -f $TypeParameterName, $ValueParameterName, ($branchingModelCategories -join ', '), ($branchingModelBranches -join ', ')) -ErrorAction $ErrorActionPreference
            return
        }
        elseif ($Value -in $branchingModelCategories)
        {
            $matcherId = $Value.ToUpperInvariant()
            $matcherDisplayId = $Value
            $matcherTypeId = 'MODEL_CATEGORY'
            $matcherTypeName = 'Branching model category'
        }
        elseif ($Value -in $branchingModelBranches)
        {
            $matcherId = $Value.ToLowerInvariant()
            $matcherDisplayId = $Value
            $matcherTypeId = 'MODEL_BRANCH'
            $matcherTypeName = 'Branching model branch'
        }
    }

    @{
        active = 'true'
        id = $matcherId
        displayId = $matcherDisplayId
        type = @{
            id = $matcherTypeId
            name = $matcherTypeName
        }
    }
}
