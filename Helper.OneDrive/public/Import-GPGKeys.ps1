function Import-GPGKeys {

    param()

    $gpgKey1drv = Get-OneDriveElementsAt -Path '/Dokumente/_Apps/_SECRET_STORE/_gpgkeys' | `
        Get-OneDriveItems | ForEach-Object { $null = gpg --import $privKey }
    
    $null = Remove-Item -Path $gpgKey1drv.Directory -Recurse
}