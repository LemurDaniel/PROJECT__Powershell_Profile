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

    PS> Get-DevOpsUser

    
    .LINK
        
#>
function Get-DevOpsUser {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $Property
    )

    $Cache = Get-UtilsCache -Type User -Identifier 'devops'
    
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

    $Request = @{
        Method = 'GET'
        Call   = 'ORG'
        Domain = 'vssps.dev.azure'
        API    = '_apis/identities?api-version=6.0'
        Query  = @{
            filterValue     = $User.emailAddress
            queryMembership = 'None'
            searchFilter     = 'General'
        }
    }
    $Identity = Invoke-DevOpsRest @Request
    $User | Add-Member NoteProperty Identity $Identity.Value -Force

    $Request = @{
        Method = 'GET'
        Call   = 'ORG'
        Domain = 'vssps.dev.azure'
        API    = "_apis/graph/users/$($Identity.Value.subjectDescriptor)?api-version=5.0-preview.1"
    }
    $graphUser = Invoke-DevOpsRest @Request
    $User | Add-Member NoteProperty GraphUser $graphUser -Force


    $null = Set-UtilsCache -Object $User -Type User -Identifier 'devops'
    return Get-Property -Object $User -Property $Property
}