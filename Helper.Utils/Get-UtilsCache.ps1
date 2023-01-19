function Get-UtilsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier
    )

    $cachePath = Join-Path -Path "$PSScriptRoot/.cache/" -ChildPath (".$Type.$Identifier.json".toLower() -replace ' ', '_') 
    $Cache = Get-Content $cachePath -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    Write-Verbose $cachePath
    if ($Cache -AND ([DateTime]$Cache.Date -gt [datetime]::Now)) {
        return $Cache.Content
    }

}