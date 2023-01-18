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

    if ($null -ne $CustomPath -And $CustomPath.length -gt 0) {
        $content = Get-Content -Path $CustomPath
        return ($noCleanNames ? $content : ($content -replace '[$]{1}[A-Za-z]+:{1}')) | ConvertFrom-Json
    }


    $Content = $null

    if ($SecretStoreSource -eq 'PERSONAL' -OR $SecretStoreSource -eq 'ALL') {
    
        $path = "$env:SECRET_STORE.private.tokenstore.json" 
        $temp = Get-Content -Path $path 
        $temp = $noCleanNames ? $temp : ($temp -replace '[$]{1}[A-Za-z]+:{1}')
        
        $temp = $temp | ConvertFrom-Json -Depth 6 | `
            Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_PER__FILEPATH___TEMP' `
            -Value $path -PassThru -Force

        $content = $temp
            
    }

    if ($SecretStoreSource -eq 'ORG' -OR $SecretStoreSource -eq 'ALL') {

        $Organization = [DevOpsOrganization]::CURRENT
        if ($Organization.length -eq 0) {
            Throw 'Not Found'
            return [PSCustomObject]@{}
        }

        # TODO Implement Check Onedrive before creating secret store
        $path = "$env:SECRET_STORE.$Organization.tokenstore.json"
        if (!(Test-Path $path)) {
            $null = (Get-Content -Path "$env:PS_PROFILE_PATH\.resources\.blueprint.tokenstore.json").Replace('~PLACEHOLDER~', $Organization) | `
                Out-File -FilePath $path
        }

        $temp = Get-Content -Path $path 
        $temp = $noCleanNames ? $temp : ($temp -replace '[$]{1}[A-Za-z]+:{1}')

        $temp = $temp | `
            ConvertFrom-Json -Depth 6 | `
            Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_ORG__FILEPATH___TEMP' `
            -Value $path -PassThru -Force

        
        if ($content) {
            $content = Join-PsObject -Object1 $content -Object2 $temp
        }
        else {
            $content = $temp
        }
    }

    return $content
}