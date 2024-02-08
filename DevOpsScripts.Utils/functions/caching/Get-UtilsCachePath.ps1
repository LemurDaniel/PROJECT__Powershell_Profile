<#
    .SYNOPSIS
    Gets the path for caching.

    .DESCRIPTION
    Gets the path for caching.

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
function Get-UtilsCachePath {

    [CmdletBinding()]
    param (
        # A path to modify the default path.
        [Parameter(
            Mandatory = $false)]
        [System.String]
        $Path,

        [Parameter()]
        [ValidateSet('Utilscache', 'Securestring', 'Configurationdata')]
        [System.String]
        $Source
    )

    switch ($Source) {
        
        "Utilscache" {
            return ![System.String]::IsNullOrEmpty($Path) ? $Path : $env:UTILS_CACHE_PATH ?? "$env:UserProfile/.devopscript.utils/.cache/"
        }

        "Securestring" {
            return ![System.String]::IsNullOrEmpty($Path) ? $Path : "$env:USERPROFILE/.devopscript.utils/.secure/"
        }

        "Configurationdata" {
            return ![System.String]::IsNullOrEmpty($Path) ? $Path : "$env:USERPROFILE/.devopscript.utils/.static"
        }

        default {
            throw [System.InvalidOperationException]("Either 'Utliscache', 'Configurationdata', or 'Securestring' must be selected!")
        }
    }

}