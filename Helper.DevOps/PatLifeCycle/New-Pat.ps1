function New-PAT {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String[]]
        $patScopes = $(
            'vso.build_execute',
            'vso.code_full',
            'vso.code_status',
            'vso.project',
            'vso.release',
            'vso.threads_full',
            'vso.tokens',
            'vso.work_write'
        ),

        [Parameter()]
        [System.String]
        $Organization,

        [Parameter()]
        [System.Int32]
        $DaysValid = 3
    )
    
        $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsCurrentContext -Organization) : $Organization
    $CurrentUser = (Get-AzContext).Account.id
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
            validTo     = ([DateTime]::now).AddDays($DaysValid)
            allOrgs     = $false
        } | ConvertTo-Json
    }

    $response = Invoke-RestMethod @Request

    return $response.patToken
}