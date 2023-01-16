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

        $token = $pat.token
    }
    else {
        $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::now) -End $expires
        if ($TIMESPAN.Days -lt 1) {
            $pat = Update-PAT -AuthorizationId $authorizationId -DaysValid 60

            Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.PAT -SecretValue $pat.token
            Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.EXPIRES -SecretValue $pat.validTo
            Update-SecretStore ORG -SecretPath CONFIG/AZURE_DEVOPS.AUTH_ID -SecretValue $pat.authorizationId

            $token = $pat.token
        }
    }

    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$((Get-AzContext).Account.Id):$($token)"))
}
