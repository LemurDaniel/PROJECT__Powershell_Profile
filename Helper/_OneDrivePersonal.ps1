

function Update-ONEDRIVE_TOKEN {
  param ()

  $ONEDRIVE = Get-PersonalSecret -SecretType ONEDRIVE_PERSONAL

  $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::Now) -End ([System.DateTime] $ONEDRIVE.expires)
  if ($TIMESPAN.Minutes -lt 2) {

    #Write-Host "Updated Token"
    $ONEDRIVE_PERSONAL_AUTHENTICATION = Get-ODAuthentication `
      -DontShowLoginScreen -AutoAccept -Scope onedrive.readonly `
      -ClientId $env:ONEDRIVE_PERSONAL_CLIENT_ID 

    Update-PersonalSecret -SecretType ONEDRIVE_PERSONAL -SecretValue $ONEDRIVE_PERSONAL_AUTHENTICATION
  }
}

function Load-ONEDRIVE_SecretStore {
  param ()

  Update-ONEDRIVE_TOKEN
  
  $SecretStoreItem = Get-Item -Path $env:SECRET_TOKEN_STORE
  $null = Get-ODItem -AccessToken $env:ONEDRIVE_PERSONAL_access_token `
    -ElementId $env:ONEDRIVE_PERSONAL_SECRET_STORE_ID `
    -LocalPath  $SecretStoreItem.PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::', '') `
    -LocalFileName $SecretStoreItem.PSChildName

}

