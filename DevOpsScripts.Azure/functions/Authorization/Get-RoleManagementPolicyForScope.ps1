
<#
    .SYNOPSIS
    Get PIM Role Management Policy for the scope.

    .DESCRIPTION
    Get PIM Role Management Policy for the scope.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of Role Management Policy for the scope.


    .EXAMPLE

    Get Role Management Policy for acfroot-dev for the Role "Storage Blob Data Contributor":

    PS> Get-RoleManagementPolicyForScope -scope "managementGroups/acfroot-dev" -roleDefintion "Storage Blob Data Contributor"

    
    .LINK
        
#>
function Get-RoleManagementPolicyForScope {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $scope,

        [Parameter()]
        [System.String]
        $roleDefintion
    )

    $roleManagementPolicyAssignment = Get-RoleManagmentPoliciyAssignmentsForScope -Scope $scope | Where-Object { $_.properties.policyAssignmentProperties.roleDefinition.displayName -eq $roleDefintion }
      
    $Request = @{
        Method = 'GET'
        Scope  = $scope
        API    = "/providers/Microsoft.Authorization/roleManagementPolicies/$($roleManagementPolicyAssignment.properties.policyId.split('/')[-1])?api-version=2020-10-01"
    }
    
    return Invoke-AzureRest @Request
}