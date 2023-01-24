function Update-OneDriveToken {
    param ()

    $1drvClientID = Get-SecretFromStore -SecretPath CONFIG/ONEDRIVE.client_id
    $TOKEN = Get-SecretFromStore CONFIG.ONEDRIVE_TOKEN

    $EXPIRES = [System.DateTime]::new(0)
    try { $EXPIRES = [System.DateTime] $TOKEN.expires } catch {}
    $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::Now) -End $EXPIRES

    if ($TIMESPAN.Minutes -lt 2) {

        $TOKEN = Get-ODAuthentication -Scope onedrive.readonly `-ClientId $1drvClientID
        $null = Update-SecretStore PERSONAL -SecretPath CONFIG.ONEDRIVE_TOKEN -SecretValue $TOKEN -Confirm:$false
    }

    return $TOKEN.access_token
}