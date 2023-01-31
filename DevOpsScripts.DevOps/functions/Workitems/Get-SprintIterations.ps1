
<#
    .SYNOPSIS
    Gets all Sprint-Iterations in the Current Project.

    .DESCRIPTION
    Gets all Sprint-Iterations in the Current Project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of all Sprint-iterations in the Project or the most current one.


    .EXAMPLE

    Get List of Sprint Iterations:

    PS> Get-SprintIterations

    .EXAMPLE

    Get Most Current Sprint Iteration:

    PS> Get-SprintIterations -Current

    .LINK
        
#>
function Get-SprintIterations {

    [CmdletBinding()]
    param(
        # Switch to only return the most current Sprint-Iteration.
        [Parameter()]
        [switch]
        $Current,

        # Switch to refresh Cached Values.
        [Parameter()]
        [switch]
        $Refresh
    )

    $Request = @{
        Method = 'GET'
        SCOPE  = 'PROJ'
        API    = '/_apis/work/teamsettings/iterations?api-version=7.0'
        Query  = $Current ? @{
            '$timeframe' = $Current ? 'current' : $Iteration
        } : $null
    }

    if ($Current) {
        return Invoke-DevOpsRest @Request -return 'value'
    }
    
    $iterations = Invoke-DevOpsRest @Request -return 'value'
    $iterations = Set-AzureDevOpsCache -Object $iterations -Type Iteration -Identifier (Get-ProjectInfo 'name')
    return $iterations
}
