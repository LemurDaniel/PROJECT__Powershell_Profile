function Get-OneDriveElementsAt {
  param (
    [Parameter()]
    [System.String]
    $Path = '/Dokumente/_Apps/_SECRET_STORE',

    [Parameter()]
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
