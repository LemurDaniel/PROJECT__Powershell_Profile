
<#
    .SYNOPSIS
    Searches an eligible PIM-Schedule Instance on a scope for a role. (DC Migration Specific)

    .DESCRIPTION
    Searches an eligible PIM-Schedule Instance on a scope for a role. At the moment only management groups.
    Validates that the current user has the schedule instance assigned.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Schedule Instance found.


    .EXAMPLE

    Get the schedule Instance for PIM-Assignment Webiste Contributor on Managment Group 'acfroot-prod':

    PS> Search-PimScheduleInstanceForUser -scope 'acfroot-prod' -role 'Webiste Contributor' -aadUserId '<id>'

    
    .LINK
        
#>
function Search-PimScheduleInstanceForUser {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $scope,

        [Parameter(Mandatory = $true)]
        [System.String]
        $role,

        [Parameter(Mandatory = $true)]
        [System.String]
        $aadUserId
    )


    # Get PIM Groups, User is Member of.
    $Request = @{
        Method = 'GET'
        ApiResource = 'users'
        ApiEndpoint    = "$aadUserId/transitiveMemberOf"
    }
    $responseGroups = Invoke-GraphApi @Request -return 'value.id'


    # Get Eligiblity Schedule Instance on Scope
    $Request = @{
        Method = 'GET'
        Scope  = $scope
        API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
    }
    $eligibleScheduleInstance = Invoke-AzureRest @Request -return 'value.properties' | `
        Where-Object { $_.expandedProperties.roleDefinition.displayName -eq $role } | `
        Where-Object -Property principalId -In ($responseGroups)
        #Sort-Object memberType
    
    if (-not $eligibleScheduleInstance) {
        throw "Not Eligible Schedule Instance found for Role '$role' on scope '$scope' on principalId '$aadUserId'"
    }

    if($eligibleScheduleInstance.GetType().BaseType -eq [System.Array]){
        return $eligibleScheduleInstance[0]
    }
    else {
        return $eligibleScheduleInstance
    }
}