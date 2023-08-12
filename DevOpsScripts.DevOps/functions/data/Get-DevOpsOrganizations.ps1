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
    param(
        [Parameter()]
        [switch]
        $Refresh
    )

    $Identifier = ((Get-AzContext).Account.id ?? "default")
    $Cache = Get-UtilsCache -Type Organization -Identifier $Identifier
    if ($Cache -AND !$Refresh) {
        return $Cache
    }

    $Organizations = @()
    $filedata = Read-SecureStringFromFile -Identifier organizations.pat.all -AsHashtable
    if ($filedata) {
        $Organizations += $filedata.Keys | ForEach-Object { 
            @{ 
                isPATauthenticated = $true
                accountName        = $_ 
            } 
        }
    }

    # TODO API currently doesn't return any data anymore!
    $Request = @{
        Method = 'GET'
        Call   = 'None'
        Domain = 'app.vssps.visualstudio'
        API    = '_apis/accounts?api-version=6.0'
        Query  = @{
            memberId = Get-DevOpsUser 'publicAlias'
        }
    }
    $Organizations += Invoke-DevOpsRest @Request -return 'value' -ErrorAction SilentlyContinue

    # TODO API currently doesn't return any data anymore!
    if (($Organizations | Measure-Object).Count -eq 0) {
        Throw "Couldnt find any DevOps Organizations associated with User: '$(Get-DevOpsUser 'displayName')' - '$(Get-DevOpsUser 'emailAddress')'"
    }

    return Set-UtilsCache -Object $Organizations -Type Organization -Identifier $Identifier

}