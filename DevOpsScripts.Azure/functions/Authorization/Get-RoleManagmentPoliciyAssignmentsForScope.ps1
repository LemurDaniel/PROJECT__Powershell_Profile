function Get-RoleManagmentPoliciyAssignmentsForScope {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $scope
    )

    $roleManagementPoliciyAssignments = Get-UtilsCache -Type roleManagmentPolicyAssignments -Identifier $scope
    if (!$roleManagementPoliciyAssignments) {

        $Request = @{
            Method = 'GET'
            Scope  = $scope
            API    = '/providers/Microsoft.Authorization/roleManagementPolicyAssignments?api-version=2020-10-01'
        }
    
        $roleManagementPoliciyAssignments = Invoke-AzureRest @Request -return 'value'
        $roleManagementPoliciyAssignments = Set-UtilsCache -Object $roleManagementPoliciyAssignments -Type roleManagmentPolicyAssignments -Identifier $scope
    } 
      
    return $roleManagementPoliciyAssignments
}