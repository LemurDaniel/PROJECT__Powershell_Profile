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
        Scope  = "/managementGroups/$scope"
        API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
    }
    $eligibleScheduleInstance = Invoke-AzureRest @Request -return 'value.properties' | `
        Where-Object { $_.expandedProperties.roleDefinition.displayName -eq $role }
    
    if (-not $eligibleScheduleInstance) {
        throw "Not Eligible Schedule Instance found for Role '$role' on scope '$scope'"
    }

    return $eligibleScheduleInstance
}