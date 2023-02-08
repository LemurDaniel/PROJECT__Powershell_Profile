
<#
    .SYNOPSIS
    Extends the Lifetime of a PAT if still valid.

    .DESCRIPTION
    Extends the Lifetime of a PAT if still valid.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The API-Response.



    .LINK
        
#>
function Update-PAT {

    [CmdletBinding()]
    param (
        # The Organozation in which the PAT shoul be created. Defaults to current Context.
        [Parameter()]
        [System.String]
        $Organization,

        # The unique Authorization ID identifing the PAT.
        [Parameter()]
        [System.Int32]
        $authorizationId,

        # How many Hours the generated PAT will be valid.
        [Parameter()]
        [System.Int32]
        $HoursValid = 8
    )
    
    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
    $CurrentUser = (Get-AzContext).Account.id
    $PatName = "User_$CurrentUser` API-generated PAT"
    $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    $Request = @{
        METHOD  = 'PUT'
        URI     = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats?api-version=7.0-preview.1"
        Headers = @{
            'Authorization' = 'Bearer ' + $token
            'Content-Type'  = 'application/json; charset=utf-8'    
        }
        Body    = @{
            displayName     = $PatName
            validTo         = ([DateTime]::now).AddHours($HoursValid)
            authorizationId = $authorizationId
            allOrgs         = $false
        } | ConvertTo-Json
    }

    $response = Invoke-RestMethod @Request

    return $response.patToken
}