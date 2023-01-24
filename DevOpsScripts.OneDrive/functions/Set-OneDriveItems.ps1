function Set-OneDriveItems {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        [Parameter(ValueFromPipeline)] 
        $localFiles,

        [Parameter()] 
        $path = '/Dokumente/_Apps/_SECRET_STORE'
    )
    Begin {
        $accessToken = Update-OneDriveToken
    }
    Process {
    
        foreach ($item in $localFiles) {
            if ($PSCmdlet.ShouldProcess("$($fileLocal.Name)" , 'Upload File to Onedrive')) {
                $null = Add-ODItem -AccessToken $accessToken -Path $path -LocalFile $item.FullName
            }
        }

    }
    End {}

}