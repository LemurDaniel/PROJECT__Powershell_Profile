<#
    .SYNOPSIS
    Get the github cache.

    .DESCRIPTION
    Get the github cache.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS

    .LINK
        
#>
function Get-GithubCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        # Return the cache as a hashtable.
        [Parameter()]
        [Switch]
        $AsHashtable,
        
        # returns data when cache expires
        [Parameter()]
        [switch]
        $ExpirationData
    )

    $Cache = @{
        Type           = [System.String]::format("{0}.{1}", (Get-GithubAccountContext).cacheRef, (Get-GithubUser).login)
        Identifier     = $Identifier
        AsHashtable    = $AsHashtable
        ExpirationData = $ExpirationData
    }
    return Get-UtilsCache @Cache

}