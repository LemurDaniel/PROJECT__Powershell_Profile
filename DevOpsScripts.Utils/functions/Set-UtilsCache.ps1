function Set-UtilsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Object,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Parameter(Mandatory = $false)]
        [System.Int16]
        $Alive = 120,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Forever
    )

    $cachePath = Join-Path -Path "$PSScriptRoot/.cache/" -ChildPath (".$Type.$Identifier.json".toLower() -replace ' ', '_') 
    
    if (-not (Test-Path -Path "$PSScriptRoot/.cache")) {
        $null = New-Item -Path "$PSScriptRoot/.cache" -ItemType Directory -Force
    }
    
    $Alive = $Forever ? [System.Int16]::MaxValue : $Alive
    @{
        Date    = ([DateTime]::Now).AddHours($Alive)
        Content = $Object
    } | ConvertTo-Json -Depth 8 | Out-File -Path $cachePath
   
    return $Object

}