#Requires -Modules @{ ModuleName="OneDrive"; ModuleVersion="2.2.0" }


function Login-ONEDRIVE_Auth {

  param ()

  Get-ODAuthentication -ClientId $env:ONEDRIVE_PERSONAL_CLIENT_ID -Scope onedrive.readonly 

}


function Update-ONEDRIVE_TOKEN {
  param ()

  $ONEDRIVE = Get-SecretFromStore -SecretType ONEDRIVE_PERSONAL

  $EXPIRES = [System.DateTime]::new(0)
  try { $EXPIRES = [System.DateTime] $ONEDRIVE.expires } catch {}
  $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::Now) -End $EXPIRES
  if ($TIMESPAN.Minutes -lt 2) {

    #Write-Host "Updated Token"
    $ONEDRIVE_PERSONAL_AUTHENTICATION = Get-ODAuthentication `
      -Scope onedrive.readonly `
      -ClientId $env:CONFIG_ONEDRIVE_PERSONAL_CLIENT_ID 

    $null = Update-SecretStore -SecretType ONEDRIVE_PERSONAL -SecretValue $ONEDRIVE_PERSONAL_AUTHENTICATION
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
  $ONEDRIVE_ITEMS = Get-ODChildItems -AccessToken $env:ONEDRIVE_PERSONAL_access_token -Path '\Dokumente\_APPS\_SECRET_STORE' `
                | Where-Object { "folder" -notin $_.PSObject.Properties.name }

  foreach ($item in $ONEDRIVE_ITEMS) {
    $null = Get-ODItem -AccessToken $env:ONEDRIVE_PERSONAL_access_token `
      -ElementId $item.id -LocalPath $env:SECRET_STORE -LocalFileName $item.name

    # $SecretStoreItem.PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::', '') `
  }
  


  if ($ShowJson) {
    Get-SecretsFromStore -ShowJSON
  }

  if ($null -ne $ONEDRIVE_PERSONAL_AUTHENTICATION) {
    $null = Update-SecretStore -SecretType ONEDRIVE_PERSONAL -SecretValue $ONEDRIVE_PERSONAL_AUTHENTICATION 
  }

  if ($ShowJson) {
    Get-SecretsFromStore -ShowJSON
  }

}

