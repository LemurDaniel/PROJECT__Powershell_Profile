<#
    .SYNOPSIS
        Creates a new Role Assignment on a Access Package Catalog.

    .DESCRIPTION
        Creates a new Role Assignment on a Access Package Catalog. 
        Uses undocumented API, not guranteed to work!
        Requires Global Administrator or Catalog Manager.

    .EXAMPLE
        
        Assign a User the Catalog Reader Role on a Catalog by id:

        PS> New-AzAccessPackageCatalogRoleAssignment `
                -RoleName "Catalog Reader" `
                -CatalogId <catalog_object_id> `
                -UserUPN <bla.bla@bla.eu>


    .LINK
     

#>


function New-AzAccessPackageCatalogRoleAssignment {

    param (
        # The Role to be assigned
        [parameter(
            Mandatory = $true
        )] 
        [ValidateSet(
            "Catalog Owner",
            "Catalog Reader",
            "Access Package Manager",
            "Access Package Assignment Manager"
        )] 
        $RoleName,

        # The Catalog Id
        [parameter(
            Mandatory = $true
        )] 
        [System.String] 
        $CatalogId,

        # User Principal Name of an Azure AD User
        [parameter(
            Mandatory = $true,
            ParameterSetName = "ADD User"
        )] 
        [System.String] 
        $UserUPN,

        # User Principal Name of an Azure AD User
        [parameter(
            Mandatory = $true,
            ParameterSetName = "ADD Group"
        )] 
        [System.String] 
        $GroupName,

        # Object id of an AD Entity
        [parameter(
            Mandatory = $true,
            ParameterSetName = "ObjectId"
        )] 
        [System.String] 
        $ObjectId
    )


    $roleDefinitionIds = @{
        "Catalog Owner"                     = "ae79f266-94d4-4dab-b730-feca7e132178"
        "Catalog Reader"                    = "44272f93-9762-48e8-af59-1b5351b1d6b3"
        "Access Package Manager"            = "7f480852-ebdc-47d4-87de-0d8498384a83"
        "Access Package Assignment Manager" = "e2182095-804a-4656-ae11-64734e9b7ae5"
    }

    [System.Byte[]]$byteArray = 1..16 | ForEach-Object { Get-Random -Max 255 }
    $Body = @{
        id                   = [System.Convert]::ToHexString($byteArray).toLower()
        principalType        = $null
        roleDefinitionId     = $roleDefinitionIds[$RoleName]
        scope                = "/AccessPackageCatalog/$CatalogId"
        accessPackageSubject = @{
            objectId = $null
        }
    } 

    if ($PSBoundParameters.ContainsKey("UserUPN")) {
        $Body.principalType = "User"
        $Body.accessPackageSubject.objectId = (Get-AzADUser -UserPrincipalName $UserUPN).id
    }
    elseif ($PSBoundParameters.ContainsKey("GroupName")) {
        $Body.principalType = "Group"
        $Body.accessPackageSubject.objectId = (Get-AzADGroup -Filter "startsWith(DisplayName,'$GroupName')").id
    }
    else {

        if ($null -eq $Body.accessPackageSubject.objectId) {
            try {
                $Body.principalType = "Group"
                $Body.accessPackageSubject.objectId = (Get-AzADGroup -ObjectId $ObjectId).id
            }
            catch {
                if (!$_.Exception.Message.Contains("[Request_ResourceNotFound]")) {
                    throw $_
                }
            }
        }

        if ($null -eq $Body.accessPackageSubject.objectId) {
            try {
                $Body.principalType = "User"
                $Body.accessPackageSubject.objectId = (Get-AzADUser -ObjectId $ObjectId).id
            }
            catch {
                if (!$_.Exception.Message.Contains("[Request_ResourceNotFound]")) {
                    throw $_
                }
            }
        }
    }

    $response = az account get-access-token --scope "https://elm.iga.azure.com/user_impersonation"
    $token = ($response | ConvertFrom-Json).accessToken
    $Request = @{
        Method  = "POST"
        Headers = @{
            "Content-Type" = "application/json"
            Authorization  = "Bearer $token"
        }
        Uri     = "https://elm.iga.azure.com/api/v1/entitlementManagementRoleAssignments"
        Body    = $Body | ConvertTo-Json -Depth 4 -Compress
    }

    return Invoke-RestMethod @Request

}

