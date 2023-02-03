
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

    Get a new PAT-Token to access repositories:

    Get-PAT -Organization 'baugruppe' -patScope vso.code_status, vso.code_status


    .LINK
        
#>

function New-PAT {

    [CmdletBinding()]
    param (
        # A list of permission scopes for the PAT.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $patScopes,

        # The Organization in which the PAT shoul be created. Defaults to current Context.
        [Parameter()]
        [System.String]
        $Organization,

        # How many Hours the generated PAT will be valid.
        [Parameter()]
        [System.Int32]
        $HoursValid = 8
    )

    $CurrentUser = (Get-AzContext).Account.id
    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
    $PatName = "User_$CurrentUser` API-generated PAT"

    $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    $Request = @{
        METHOD  = 'POST'
        URI     = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats?api-version=7.0-preview.1"
        Headers = @{
            'Authorization' = 'Bearer ' + $token
            'Content-Type'  = 'application/json; charset=utf-8'    
        }
        Body    = @{
            displayName = $PatName
            scope       = $patScopes -join ' '
            validTo     = ([DateTime]::now).AddHours($HoursValid)
            allOrgs     = $false
        } | ConvertTo-Json
    }

    return Invoke-RestMethod @Request | Select-Object -ExpandProperty patToken

}