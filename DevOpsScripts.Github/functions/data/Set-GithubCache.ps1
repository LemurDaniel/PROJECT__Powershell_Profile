<#
    .SYNOPSIS
    Set the Cache-Content of an Github Cache.

    .DESCRIPTION
    Set the Cache-Content of an Github Cache to reduce API-Calls

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    PSObject of the Cache-Content.

    
    .LINK
        
#>
function Set-GithubCache {

    [CmdletBinding()]
    param (
        # The Powershell Object to be cached.
        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $Object = @{},

        # The Type of the cache like Pipeline, Project, etc.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # An identifier like name of the project, all, current, etc.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        # The TTL of the cache in Minutes.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $Alive = 60,

        # A Flag to never expire the cache.
        [Parameter(Mandatory = $false)]
        [switch]
        $Forever
    )

    $parameters = @{
        Object     = $Object
        Type       = $Type
        identifier = "$((Get-GitUser).login).$Identifier"
        Alive      = $Alive
        Forever    = $Forever
    }
    return Set-UtilsCache @parameters

}