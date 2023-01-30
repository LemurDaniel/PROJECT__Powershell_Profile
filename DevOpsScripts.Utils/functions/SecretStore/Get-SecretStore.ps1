function Get-SecretStore {
    param (
        [parameter()]
        [SecretScope]
        $SecretStoreSource = 'ALL',

        [parameter()]
        [switch]
        $noCleanNames,

        # Test
        [Parameter()]
        $CustomPath 
    )

    if (![System.String]::IsNullOrEmpty($CustomPath)) {
        $content = Get-Content -Path $CustomPath
        return ($noCleanNames ? $content : ($content -replace '[$]{1}[A-Za-z]+:{1}')) | ConvertFrom-Json
    }

    $path = "$env:SECRET_STORE.private.tokenstore.json" 
    $Content = Get-Content -Path $path 
    $Content = $noCleanNames ? $Content : ($Content -replace '[$]{1}[A-Za-z]+:{1}')
        
    return $Content | ConvertFrom-Json -Depth 6 | `
        Add-Member -MemberType NoteProperty -Name 'SECRET_STORE__FILEPATH' `
        -Value $path -PassThru -Force

}