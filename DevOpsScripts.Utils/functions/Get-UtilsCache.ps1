
<#
    .SYNOPSIS
    Gets a Property based on a Property path of an Object or an Array of Objects.

    .DESCRIPTION
    Gets a Property based on a Property path of an Object or an Array of Objects.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Returns the Property or Array of Properties if found.


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
        $AsHashtable,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Path = "$PSScriptRoot/.cache/"
    )

    try {
        $cachePath = Join-Path -Path $Path -ChildPath (".$Type.$Identifier.json".toLower() -replace '[\/\\\s]+', '_') 
        $Cache = Get-Content $cachePath | ConvertFrom-Json -AsHashtable:$AsHashtable 

        Write-Verbose $cachePath
        
        if ([DateTime]$Cache.Date -gt [datetime]::Now) {
            return $Cache.Content
        }      
    }
    catch {
        return $null
    }

}