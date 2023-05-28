
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
        $Path = $null,

        # returns data when cache expires
        [Parameter()]
        [switch]
        $ExpirationData
    )

    try {
        $CacheFolderPath = ![System.String]::IsNullOrEmpty($Path) ? $Path : $env:UTILS_CACHE_PATH ?? "$([System.IO.Path]::GetTempPath())/.cache/"
        $CacheFilePath = Join-Path -Path $CacheFolderPath -ChildPath (".$Type.$Identifier.json".toLower() -replace '[\/\\\s]+', '_') 

        Write-Verbose $CacheFilePath

        $Cache = Get-Content $CacheFilePath | ConvertFrom-Json -AsHashtable:$AsHashtable 
        if ([DateTime]$Cache.Date.toUniversalTime() -gt [datetime]::Now.toUniversalTime()) {
            
            if ($ExpirationData) {
                return @{
                    ExpiresIn = $Cache.Date.toUniversalTime() - [System.DateTime]::Now.toUniversalTime()
                    Date      = $Cache.Date
                    Content   = $Cache.Content
                }
            }
            else {
                return $Cache.Content
            }
        }      
    }
    catch {
        return $null
    }

}