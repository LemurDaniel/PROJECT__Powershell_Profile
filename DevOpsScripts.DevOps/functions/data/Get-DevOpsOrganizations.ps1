<#
    .SYNOPSIS
    Get all DevOps Organization the current User has Acces to.

    .DESCRIPTION
    Get all DevOps Organization the current User has Acces to.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Name of all Organizations connected to the Account.


    .EXAMPLE

    Gets all organizations conected to the user.

    PS> Get-DevOpsContext -Organization
    
    .LINK
        
#>
function Get-DevOpsOrganizations {

    [cmdletbinding()]
    param()

    $Cache = Get-UtilsCache -Type Organization -Identifier ((Get-AzContext).Account.id)
    if ($Cache) {
        return $Cache
    }

    # Get Organizations the user is member of.
    $Request = @{
        Method = 'GET'
        Call   = 'None'
        Domain = 'app.vssps.visualstudio'
        API    = '_apis/accounts?api-version=6.0'
        Query  = @{
            memberId = Get-DevOpsUser 'publicAlias'
        }
    }

    $Organizations = Invoke-DevOpsRest @Request -return 'value'

    if (($Organizations | Measure-Object).Count -eq 0) {
        Throw "Couldnt find any DevOps Organizations associated with User: '$(Get-DevOpsUser 'displayName')' - '$(Get-DevOpsUser 'emailAddress')'"
    }
    return Set-UtilsCache -Object $Organizations -Type Organization -Identifier ((Get-AzContext).Account.id)

}