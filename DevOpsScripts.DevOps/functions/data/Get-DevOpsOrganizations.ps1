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



    # Organizations added via PAT.
    $Organizations = @()
    $filedata = Read-SecureStringFromFile -Identifier organizations.pat.all -AsHashtable
    if ($filedata) {
        $Organizations += $filedata.Keys | ForEach-Object { 
            @{ 
                accountId          = $null
                accountUri         = $null
                tenantId           = $null
                isPATauthenticated = $true
                accountName        = $_ 
            } 
        }
    }


    
    Get-AzTenant | ForEach-Object {

        $tenantId = $_.id
        $Request = @{
            TenantId = $tenantId
            Method   = 'GET'
            Call     = 'None'
            Domain   = 'app.vssps.visualstudio'
            API      = '_apis/accounts?api-version=6.0'
            Query    = @{
                # Note the same user on each tenant has a different publicAlias and needs to be called for every tenant.
                # TODO fix same problem in VsCode Extension
                memberId = (Get-DevOpsUser).publicAliases."$tenantId"
            }
        }

        $response = Invoke-DevOpsRest @Request  -ErrorAction SilentlyContinue 

        if ($null -NE $response -OR $response.count -gt 0) {

            $Organizations += $response | Select-Object -ExpandProperty value -ErrorAction SilentlyContinue
            | ForEach-Object {
                $_ | Add-Member NoteProperty isPATauthenticated $false
                $_ | Add-Member NoteProperty tenantId $tenantId -PassThru
                $_ | Add-Member NoteProperty publicAlias (Get-DevOpsUser).publicAliases."$tenantId"
            }

        }
    }


    if (($Organizations | Measure-Object).Count -eq 0) {
        Throw "Couldnt find any DevOps Organizations associated with User: '$(Get-DevOpsUser 'displayName')' - '$(Get-DevOpsUser 'emailAddress')'"
    }

    return Set-UtilsCache -Object $Organizations -Type Organization -Identifier $Identifier -Alive 1200

}