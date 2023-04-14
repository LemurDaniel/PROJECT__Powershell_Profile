<#
    .SYNOPSIS
    Get the Cache-Content of an Github Cache.

    .DESCRIPTION
    Get the Cache-Content of an Github Cache to reduce API-Calls

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    PSObject of the Cache-Content.

    
    .LINK
        
#>
function Get-GithubCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier
    )

    return Get-UtilsCache -Type $Type -Identifier "$((Get-GitUser).login).$Identifier"

}