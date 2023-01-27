function Get-RoleEligibilitySceduleInstancesForScope {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $scope
    )

    $RoleEligibilitySceduleInstances = Get-UtilsCache -Type RoleEligibilitySceduleInstances -Identifier $scope
    if (!$RoleEligibilitySceduleInstances) {

        $Request = @{
            Method = 'GET'
            Scope  = $scope
            API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
        }
    
        $RoleEligibilitySceduleInstances = Invoke-AzureRest @Request -return 'value.properties'
        $RoleEligibilitySceduleInstances = Set-UtilsCache -Object $RoleEligibilitySceduleInstances -Type RoleEligibilitySceduleInstances -Identifier $scope
    } 
      


    return $RoleEligibilitySceduleInstances
}