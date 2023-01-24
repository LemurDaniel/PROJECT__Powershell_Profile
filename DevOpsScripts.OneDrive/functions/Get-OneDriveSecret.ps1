function Get-OneDriveSecretStore {
    param ()

    $oneDriveItems = Get-OneDriveElementsAt -Path '/Dokumente/_Apps/_SECRET_STORE' -FileOnly
    $accessToken = Update-OneDriveToken
    foreach ($item in $oneDriveItems) {
        $null = Get-ODItem -AccessToken $accessToken `
            -ElementId $item.id -LocalPath $env:SECRET_STORE -LocalFileName $item.name`
  
    }
  
}