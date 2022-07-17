#Requires -Modules @{ ModuleName="OneDrive"; ModuleVersion="2.2.0" }


function Login-ONEDRIVE_Auth {

  param ()

  Get-ODAuthentication  -ClientId $env:ONEDRIVE_PERSONAL_CLIENT_ID  -Scope onedrive.readonly 

}

function Update-ONEDRIVE_TOKEN {
  param ()

  $ONEDRIVE = Get-PersonalSecret -SecretType ONEDRIVE_PERSONAL

  $EXPIRES = [System.DateTime]::new(0)
  try {$EXPIRES = [System.DateTime] $ONEDRIVE.expires} catch{}
  $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::Now) -End $EXPIRES
  if ($TIMESPAN.Minutes -lt 2) {

    #Write-Host "Updated Token"
    $ONEDRIVE_PERSONAL_AUTHENTICATION = Get-ODAuthentication `
      -DontShowLoginScreen -AutoAccept -Scope onedrive.readonly `
      -ClientId $env:ONEDRIVE_PERSONAL_CLIENT_ID 

    $null = Update-PersonalSecret -SecretType ONEDRIVE_PERSONAL -SecretValue $ONEDRIVE_PERSONAL_AUTHENTICATION
  }

  return $ONEDRIVE_PERSONAL_AUTHENTICATION
}

function Load-ONEDRIVE_SecretStore {
  param (
    [Parameter()]
    [Switch]
    $ShowJSON
  )

  $ONEDRIVE_PERSONAL_AUTHENTICATION = Update-ONEDRIVE_TOKEN
  
  $SecretStoreItem = Get-Item -Path $env:SECRET_TOKEN_STORE
  $null = Get-ODItem -AccessToken $env:ONEDRIVE_PERSONAL_access_token `
    -ElementId $env:ONEDRIVE_PERSONAL_SECRET_STORE_ID `
    -LocalPath  $SecretStoreItem.PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::', '') `
    -LocalFileName $SecretStoreItem.PSChildName

  if ($ShowJson) {
    Load-PersonalSecrets -ShowJSON
  }

  $null = Update-PersonalSecret -SecretType ONEDRIVE_PERSONAL -SecretValue $ONEDRIVE_PERSONAL_AUTHENTICATION

  if ($ShowJson) {
    Load-PersonalSecrets -ShowJSON
  }

}

