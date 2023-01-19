function Get-AzureDevOpsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier
    )

    $Organization = Get-DevOpsCurrentContext -Organization
    $cachePath = Join-Path -Path "$PSScriptRoot/../.cache/" -ChildPath (".$Type.$Organization.$Identifier.json".toLower() -replace ' ', '_') 
    $Cache = Get-Content $cachePath -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if ($Cache -AND ([DateTime]$Cache.Date -gt [datetime]::Now)) {
        return $Cache.Content
    }

}


function Set-AzureDevOpsCache {

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
        $Alive = 7
    )

    $Organization = Get-DevOpsCurrentContext -Organization
    $cachePath = Join-Path -Path "$PSScriptRoot/../.cache/" -ChildPath (".$Type.$Organization.$Identifier.json".toLower() -replace ' ', '_') 
    @{
        Date = ([DateTime]::Now).AddDays($Alive)
        Content = $Object
    } | ConvertTo-Json -Depth 8 | Out-File $cachePath
   
    return $Object

}