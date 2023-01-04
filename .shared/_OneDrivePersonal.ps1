#Requires -Modules @{ ModuleName="OneDrive"; ModuleVersion="2.2.0" }


function Update-OneDriveToken {
  param ()

  $1drvClientID = Get-SecretFromStore -SecretPath CONFIG/ONEDRIVE.client_id
  $TOKEN = Get-SecretFromStore CONFIG.ONEDRIVE_TOKEN

  $EXPIRES = [System.DateTime]::new(0)
  try { $EXPIRES = [System.DateTime] $TOKEN.expires } catch {}
  $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::Now) -End $EXPIRES
  if ($TIMESPAN.Minutes -lt 2) {

    #Write-Host "Updated Token"
    $TOKEN = Get-ODAuthentication `
      -Scope onedrive.readonly `
      -ClientId $1drvClientID

    $null = Update-SecretStore PERSONAL -SecretPath CONFIG.ONEDRIVE_TOKEN -SecretValue $TOKEN
  }

  return $TOKEN.access_token
}

function Get-OneDriveSecretStore {
  param ()

  $oneDriveItems = Get-OneDriveElementsAt -Path '/Dokumente/_Apps/_SECRET_STORE' -FileOnly
  $accessToken = Update-OneDriveToken

  foreach ($item in $oneDriveItems) {
    $null = Get-ODItem -AccessToken $accessToken `
      -ElementId $item.id -LocalPath $env:SECRET_STORE -LocalFileName $item.name

    # $SecretStoreItem.PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::', '') `
  }
  
}


function Get-OneDriveElementsAt {
  param (
    [System.String]
    $Path = '/Dokumente/_Apps/_SECRET_STORE',

    [switch]
    $FileOnly
  )

  $accessToken = Update-OneDriveToken
  $items = Get-ODChildItems -AccessToken $accessToken -Path $path
  
  if ($fileOnly) {
    return $items | Where-Object { 'folder' -notin $_.PSObject.Properties.name }
  }
  else {
    return $items
  }
}


function Get-OneDriveItems {

  [CmdletBinding()]  
  param (
    [Parameter(ValueFromPipeline)] 
    $1driveFiles 
  )
  Begin {
  
    $byteArray = (1..32 | ForEach-Object { [byte](Get-Random -Max 256) })
    $randomString = [System.Convert]::ToHexString(($byteArray))
    $Outpath = "C:$env:HOMEPATH\downloads\$randomString"

    $directory = New-Item -Path $Outpath -ItemType Directory

  }
  Process {
    
    $accessToken = Update-OneDriveToken
    foreach ($item in $1driveFiles) {
      $null = Get-ODItem -AccessToken $accessToken `
        -ElementId $item.id -LocalPath $Outpath -LocalFileName $item.name
    }

  }
  End {
    return Get-ChildItem -Path $directory.FullName
  }
}
