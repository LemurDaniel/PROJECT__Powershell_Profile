
<#
    .SYNOPSIS
    Get PIM Role Management Policy Assignments for the scope.

    .DESCRIPTION
    Get PIM Role Management Policy Assignments for the scope.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of Role Management Policy Assignments for the scope.


    .EXAMPLE

    Get Role Management Policy Assignments for acfroot-dev:

    PS> Get-RoleManagmentPoliciyAssignmentsForScope -scope "managementGroups/acfroot-dev"

    
    .LINK
        
#>
function Get-RoleManagmentPoliciyAssignmentsForScope {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $scope
    )

    $roleManagementPolicyAssignments = Get-UtilsCache -Type roleManagmentPolicyAssignments -Identifier $scope
    if (!$roleManagementPolicyAssignments) {

        $Request = @{
            Method = 'GET'
            Scope  = $scope
            API    = '/providers/Microsoft.Authorization/roleManagementPolicyAssignments?api-version=2020-10-01'
        }
    
        $roleManagementPolicyAssignments = Invoke-AzureRest @Request | Select-Object -ExpandProperty value
        $roleManagementPolicyAssignments = Set-UtilsCache -Object $roleManagementPolicyAssignments -Type roleManagmentPolicyAssignments -Identifier $scope
    } 
      
    return $roleManagementPolicyAssignments
}