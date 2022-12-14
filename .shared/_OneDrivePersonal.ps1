#Requires -Modules @{ ModuleName="OneDrive"; ModuleVersion="2.2.0" }


function Login-ONEDRIVE_Auth {

  param ()

  Get-ODAuthentication -ClientId $env:ONEDRIVE_CLIENT_ID -Scope onedrive.readonly 

}


function Update-ONEDRIVE_TOKEN {
  param ()

  $TOKEN = Get-SecretFromStore CONFIG.ONEDRIVE_TOKEN

  $EXPIRES = [System.DateTime]::new(0)
  try { $EXPIRES = [System.DateTime] $TOKEN.expires } catch {}
  $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::Now) -End $EXPIRES
  if ($TIMESPAN.Minutes -lt 2) {

    #Write-Host "Updated Token"
    $TOKEN = Get-ODAuthentication `
      -Scope onedrive.readonly `
      -ClientId $env:ONEDRIVE_CLIENT_ID

    $null = Update-SecretStore PERSONAL -SecretPath CONFIG.ONEDRIVE_TOKEN -SecretValue $TOKEN
  }

  return $TOKEN.access_token
}

function Load-ONEDRIVE_SecretStore {
  param ()

  $accessToken = Update-ONEDRIVE_TOKEN
  $ONEDRIVE_ITEMS = Get-ODChildItems -AccessToken $accessToken -Path $env:SECRET_STORE `
  | Where-Object { 'folder' -notin $_.PSObject.Properties.name }

  foreach ($item in $ONEDRIVE_ITEMS) {
    $null = Get-ODItem -AccessToken $accessToken `
      -ElementId $item.id -LocalPath $env:SECRET_STORE -LocalFileName $item.name

    # $SecretStoreItem.PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::', '') `
  }
  
}

