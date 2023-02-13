
<#
    .SYNOPSIS
    Gets the organizational lead for a user from graph api as configured by company.

    .DESCRIPTION
    Gets the organizational lead for a user from graph api as configured by company.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None



    .LINK
        
#>


function Get-GraphApiManager {
    param (
        [Parameter()]
        [System.String]
        $usermail
    )

    $userId = (Get-AzADUser -Mail $usermail).id
    return Invoke-GraphApi -Api "/users/$userId/manager"

}