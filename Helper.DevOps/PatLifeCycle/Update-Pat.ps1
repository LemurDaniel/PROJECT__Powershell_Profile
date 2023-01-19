function Update-PAT {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Organization,

        [Parameter()]
        [System.Int32]
        $authorizationId,

        [Parameter()]
        [System.Int32]
        $DaysValid
    )
    
    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsCurrentContext -Organization) : $Organization
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
            validTo         = ([DateTime]::now).AddDays($DaysValid)
            authorizationId = $authorizationId
            allOrgs         = $false
        } | ConvertTo-Json
    }

    $response = Invoke-RestMethod @Request

    return $response.patToken
}