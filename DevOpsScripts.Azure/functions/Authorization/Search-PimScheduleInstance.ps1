
<#
    .SYNOPSIS
    Searches an eligible PIM-Schedule Instance on a scope for a role.

    .DESCRIPTION
    Searches an eligible PIM-Schedule Instance on a scope for a role. At the moment only management groups.
    Can return multiple schedule instances. Current DC Migartion Infrastructure, only one Eligible PIM-Aissgnment per role, per scope.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Schedule Instance found.


    .EXAMPLE

    Get the schedule Instance for PIM-Assignment Webiste Contributor on Managment Group 'acfroot-prod':

    PS> Search-PimScheduleInstance -scope 'acfroot-prod' -role 'Webiste Contributor'

    
    .LINK
        
#>
function Search-PimScheduleInstance {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $scope,

        [Parameter(Mandatory = $true)]
        [System.String]
        $role
    )

    # Get any scheduleinstance on scope. We only have pim-role assignment per scope.
    # Runs into error later, when user not assigned to group and therefore has no eligibility.

    # Get Eligiblity Schedule Instance on Scope
    $Request = @{
        Method = 'GET'
        Scope  = $scope
        API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
    }
    $eligibleScheduleInstance = Invoke-AzureRest @Request | Select-Object -ExpandProperty value | Select-Object -ExpandProperty properties | `
        Where-Object { $_.expandedProperties.roleDefinition.displayName -eq $role } | `

    
    
    if (-not $eligibleScheduleInstance) {
        throw "Not Eligible Schedule Instance found for Role '$role' on scope '$scope'"
    }

    return $eligibleScheduleInstance
}