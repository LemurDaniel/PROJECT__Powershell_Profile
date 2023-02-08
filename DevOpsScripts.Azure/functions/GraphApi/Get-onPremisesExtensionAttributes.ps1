
<#
    .SYNOPSIS
    Gets Extension Attributes for the current user.

    .DESCRIPTION
    Gets Extension Attributes for the current user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None



    .LINK
        
#>

function  Get-onPremisesExtensionAttributes {
    param (
        [Parameter()]
        [System.String]
        $usermail
    )

    $userId = (Get-AzADUser -Mail $usermail).id
    return Invoke-GraphApi -ApiEndpoint "users/$userId/onPremisesExtensionAttributes"
  
}