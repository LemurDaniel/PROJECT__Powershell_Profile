function Get-UtilsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Alias('return')]
        [Parameter(Mandatory = $false)]
        [System.String]
        $Property
    )

    $cachePath = Join-Path -Path "$PSScriptRoot/.cache/" -ChildPath (".$Type.$Identifier.json".toLower() -replace ' ', '_') 
    $Cache = Get-Content $cachePath -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    Write-Verbose $cachePath
    if ($Cache -AND ([DateTime]$Cache.Date -gt [datetime]::Now)) {
        return Get-Property -Object $Cache.Content -Property $Property
    }

}