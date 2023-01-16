function Search-PAT {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Organization = 'baugruppe'
    )

    $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    $Request = @{
        METHOD = 'GET'
        URI    = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats?api-version=7.0-preview.1"
        Header = @{
            'Authorization' = 'Bearer ' + $token
            'Content-Type'  = 'application/json; charset=utf-8'    
        }
    }
    $response = Invoke-RestMethod @Request

    $CurrentUser = (Get-AzContext).Account.id
    $PatName = "User_$CurrentUser*"
    return $response.patTokens | Where-Object -Property displayName -Like -Value $PatName
}