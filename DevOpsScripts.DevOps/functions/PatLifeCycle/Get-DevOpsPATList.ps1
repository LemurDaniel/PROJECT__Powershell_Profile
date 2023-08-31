
<#
    .SYNOPSIS
    Generates a new PAT-Token for the DevOps API with specified Permissions.

    .DESCRIPTION
    Generates a new PAT-Token for the DevOps API with specified Permissions.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The API-Response containing the PAT as Plaint-text.


    .EXAMPLE

    Get a list of PATs for an organization and revoke them: (Note: tokens won't be retrieved)

    PS> Get-DevOpsPATList -TenantId "3d355765-67d9-47cd-9c7a-bf31179f56eb" -Organization 'oliver-hammer'
        | Where-Object -Property displayName -like "*test*"
        | Revoke-DevOpsPAT


    .LINK
        
#>

function Get-DevOpsPATList {

    [CmdletBinding()]
    param (

        # The AzureAd tenant id to wich the organization is connected to.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $TenantId,
        
        # The Organization in which the PAT shoul be created. Defaults to current Context.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Organization
    )

    $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $TenantId).Token
    $Request = @{
        METHOD  = 'GET'
        URI     = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats?api-version=7.0-preview.1"
        Headers = @{
            'Authorization' = "Bearer $token"
            'Content-Type'  = 'application/json; charset=utf-8'    
        }
    }

    return Invoke-RestMethod @Request 
    | Select-Object -ExpandProperty patTokens
    | Add-Member -MemberType NoteProperty -Name tenantId -Value $TenantId -PassThru
    | Add-Member -MemberType NoteProperty -Name organization -Value $Organization -PassThru
    | Select-Object -Property @{
        Name       = "transformation";
        Expression = { 
            return [PSCustomObject]@{
                displayName     = $_.displayName
                organization    = $_.organization
                tenantId        = $_.tenantId
                token           = $_.token
                authorizationId = $_.authorizationId
                scope           = $_.scope.split(' ') 
                validFrom       = $_.validFrom
                validTo         = $_.validTo
                targetAccounts  = $_.targetAccounts
            } 
        }
    }
    | Select-Object -ExpandProperty transformation

}