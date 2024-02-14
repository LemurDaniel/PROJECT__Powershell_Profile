<#
    .SYNOPSIS
    Get the Git cache.

    .DESCRIPTION
    Get the Git cache.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS

    .LINK
        
#>
function Get-GitCache {

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
        $ExpirationData,

        [Parameter()]
        [System.String]
        $Account,

        [Parameter()]
        [System.String]
        $Context,

        [Parameter()]
        [System.String]
        $Repository
    )

    $Cache = @{
        Type           = [System.String]::format("{0}.{1}", (Get-GitAccountContext -Account $Account).cacheRef, (Get-GitUser -Account $Account).login)
        Identifier     = (@($Identifier, $Context, $Repository) | Where-Object { ![System.String]::IsNullOrEmpty($_) }) -join '.'
        AsHashtable    = $AsHashtable
        ExpirationData = $ExpirationData
    }
    return Get-UtilsCache @Cache

}