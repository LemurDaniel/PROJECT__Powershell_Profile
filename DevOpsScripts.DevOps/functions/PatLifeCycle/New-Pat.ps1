
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
         # The optional Name of the retrieved or newly created pat.
        [Parameter(
          Mandatory = $false
        )]
        [System.String]
        $Name,

        # The Organozation in which the PAT shoul be created. Defaults to current Context.
        [Parameter(
          Mandatory = $true
        )]
        [System.String]
        $Organization,

        # A list of permission scopes for the PAT.
        [Parameter(
          Mandatory = $true
        )]
        [System.String[]]
        $PatScopes,

        # How many Hours the generated PAT will be valid.
        [Parameter()]
        [System.Int32]
        $HoursValid = 8
    )

    $CurrentUser = (Get-AzContext).Account.id
    
    $PatName =  [System.String]::IsNullOrEmpty($Name) ? "User_$CurrentUser` API-generated PAT" : $Name

    # TODO generate pat token for correct tenant
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
            scope       = $PatScopes -join ' '
            validTo     = [DateTime]::now.ToUniversalTime().AddHours($HoursValid)
            allOrgs     = $false
        } | ConvertTo-Json
    }

    return Invoke-RestMethod @Request | Select-Object -ExpandProperty patToken

}