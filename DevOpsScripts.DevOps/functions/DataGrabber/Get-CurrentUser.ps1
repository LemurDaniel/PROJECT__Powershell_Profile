<#
    .SYNOPSIS
    Get Information about the current DevOps-User loggedin via Connect-AzAccount.

    .DESCRIPTION
    Get Information about the current DevOps-User loggedin via Connect-AzAccount.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Fullinformation of the current user or an attribute specified by Property.


    .EXAMPLE

    Gets the Current User in Azure DevOps:

    PS> Get-CurrentUser

    
    .LINK
        
#>
function Get-CurrentUser {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $Property
    )

    $Cache = Get-UtilsCache -Type User -Identifier 'current'
    
    if ($Cache -AND $Cache.emailAddress.toLower() -eq (Get-AzContext).Account.Id.ToLower()) {
        return Get-Property -Object $Cache -Property $Property
    }


    $Request = @{
        Method = 'GET'
        Call   = 'None'
        Domain = 'app.vssps.visualstudio'
        API    = '_apis/profile/profiles/me?api-version=6.0'
    }

    $User = Invoke-DevOpsRest @Request

    $null = Set-UtilsCache -Object $User -Type User -Identifier 'current'
    return Get-Property -Object $User -Property $Property
}