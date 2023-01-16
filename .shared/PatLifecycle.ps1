

function Get-Pat {
    param (
        [Parameter()]
        [System.String]
        $Organization = 'baugruppe'
    )

    $token = Get-SecretFromStore CONFIG/AZURE_DEVOPS.PAT -ErrorAction SilentlyContinue
    $expires = Get-SecretFromStore CONFIG/AZURE_DEVOPS.EXPIRES -ErrorAction SilentlyContinue
    $authorizationId = Get-SecretFromStore CONFIG/AZURE_DEVOPS.AUTH_ID -ErrorAction SilentlyContinue

    if (!$token) {
        $pat = New-PAT -DaysValid 60
        Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.PAT -SecretValue $pat.token
        Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.EXPIRES -SecretValue $pat.validTo
        Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.AUTH_ID -SecretValue $pat.authorizationId

        return $pat.token
    }

    $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::now) -End $expires
    if ($TIMESPAN.Days -lt 1) {
        $pat = Update-PAT -DaysValid 60

        Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.PAT -SecretValue $pat.token
        Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.EXPIRES -SecretValue $pat.validTo
        Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.AUTH_ID -SecretValue $pat.authorizationId

        return $pat.token
    }

    return $token
}

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



function Update-PAT {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Organization = 'baugruppe',

        [Parameter()]
        [System.Int32]
        $authorizationId,

        [Parameter()]
        [System.Int32]
        $DaysValid
    )
    
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
    #Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS -SecretValue $AzureDevops
}



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
        $Organization = 'baugruppe',

        [Parameter()]
        [System.Int32]
        $DaysValid = 3
    )
    
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


function Update-PatExpiration {

    param()

    if (Is-PatExpired) {
        Write-Host -ForegroundColor RED 'PAT has expired. Download newer Version of tokenstore from Onedrive.'
        Get-OneDriveSecretStore
    }

    if ((Is-PatExpired)) {
        Update-PatToken
        $pathLocal = Get-SecretFromStore SECRET_STORE_ORG__FILEPATH___TEMP
        $fileLocal = Get-Item -Path $pathLocal
        $fileLocal | Set-OneDriveItems -Path '/Dokumente/_Apps/_SECRET_STORE'
    }

}