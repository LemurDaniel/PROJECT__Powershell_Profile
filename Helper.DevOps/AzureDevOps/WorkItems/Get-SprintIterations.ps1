function Get-SprintIterations {

    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]
        $Current,

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
    

    $Cache = Get-AzureDevOpsCache -Type Iteration -Identifier (Get-ProjectInfo 'name')
    if ($Cache -AND !$Refresh) {
        return $Cache
    }


    $iterations = Invoke-DevOpsRest @Request -return 'value'
    return Set-AzureDevOpsCache -Object $iterations -Type Iteration -Identifier (Get-ProjectInfo 'name')
}
