function Get-PAT {
    param (
        [Parameter()]
        [System.String]
        $Organization = 'baugruppe',

        [Parameter()]
        [System.String[]]
        $patScopes,

        [Parameter()]
        [System.Int32]
        $HoursValid = 8,

        [Parameter()]
        [System.String]
        $Path = "$PSScriptRoot/.local"
    )


    if(!(Test-Path -Path $path)){
        $null = New-Item -ItemType Directory -Path $path
    }

    $localPat = Read-SecureStringFromFile -Identifier "pat.$Organization" -AsPlainText -Path $Path | ConvertFrom-Json

    if($null -ne $patScope -AND ($localPat.patScopes -Join ';') -ne ($patScopes -Join ';') -OR $localPat.validTo -lt [DateTime]::now) {
        $localPat = New-PAT -Organization $Organization -patScopes $patScopes -HoursValid $HoursValid | `
            Select-Object -Property displayName, validTo, scope, authorizationId, @{
                Name = 'pass';
                Expression = {
                    $_.token | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
                }
            }, @{
                Name = 'user';
                Expression = {
                    (Get-AzContext).Account.id
                }
            }

        Save-SecureStringToFile -PlainText ($localPat | ConvertTo-Json -Compress) -Identifier "pat.$Organization" -Path $Path
    }

    $localPat.pass = $localPat.pass | ConvertTo-SecureString
    return New-Object System.Management.Automation.PSCredential($localPat.user, $localPat.pass)
}