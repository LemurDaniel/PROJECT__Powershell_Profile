
<#
    .SYNOPSIS
    Gets a chached value by a type and a specified identifier.

    .DESCRIPTION
    Gets a chached value by a type and a specified identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return null or the Cached value if present.


    .EXAMPLE

    Get the current User cached back:

    PS> Get-UtilsCache -Type User -Identifier current

        .EXAMPLE

    Get all PIM Profiles as a hashtable back.

    PS> Get-UtilsCache -Type PIM_Profiles -Identifier all -AsHashtable
    
    .LINK
        
#>
function Get-UtilsCache {

    [CmdletBinding()]
    param (
        # The type of the cache.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # An identifier for the cache.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        # Return the cache as a hashtable.
        [Parameter()]
        [Switch]
        $AsHashtable
    )

    $cachePath = Join-Path -Path "$PSScriptRoot/.cache/" -ChildPath (".$Type.$Identifier.json".toLower() -replace ' ', '_') 
    $Cache = Get-Content $cachePath -ErrorAction SilentlyContinue | ConvertFrom-Json -AsHashtable:$AsHashtable -ErrorAction SilentlyContinue
    
    Write-Verbose $cachePath
    if ($Cache -AND ([DateTime]$Cache.Date -gt [datetime]::Now)) {
        return $Cache.Content
    }

}