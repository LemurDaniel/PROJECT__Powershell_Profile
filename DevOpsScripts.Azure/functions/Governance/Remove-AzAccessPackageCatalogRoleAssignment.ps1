<#
    .SYNOPSIS
        Removes a Role Assignment on a Access Package Catalog.

    .DESCRIPTION
        Removes a Role Assignment on a Access Package Catalog. 
        Uses undocumented API, not guranteed to work!
        Requires Global Administrator or Catalog Manager.

    .EXAMPLE
        
        Assign a User the Catalog Reader Role on a Catalog by id:

        PS> $roleAssignment = New-AzAccessPackageCatalogRoleAssignment `
                -RoleName "Catalog Reader" `
                -CatalogId <catalog_object_id> `
                -UserUPN <bla.bla@bla.eu>
        
        PS> $roleAssignment

        PS> #Then delete it again:

        PS> Remove-AzAccessPackageCatalogRoleAssignment `
                -RoleAssignmentId $roleAssignment.id


    .LINK
     

#>

function Remove-AzAccessPackageCatalogRoleAssignment {

    param (
        # The Role to be assigned
        [parameter(
            Mandatory = $true
        )] 
        [System.String]
        $RoleAssignmentId
    )

    $response = az account get-access-token --scope "https://elm.iga.azure.com/user_impersonation"
    $token = ($response | ConvertFrom-Json).accessToken
    $Request = @{
        Method  = "DELETE"
        Headers = @{
            Authorization = "Bearer $token"
        }
        Uri     = "https://elm.iga.azure.com/api/v1/entitlementManagementRoleAssignments('$RoleAssignmentId')"
    }

    return Invoke-RestMethod @Request

}

