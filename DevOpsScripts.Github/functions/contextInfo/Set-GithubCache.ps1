<#
    .SYNOPSIS
    Set the github cache.

    .DESCRIPTION
    Set the github cache.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS

    .LINK
        
#>
function Set-GithubCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Object,
    
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,
    
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Alive = 720,
    
        [Parameter(Mandatory = $false)]
        [Switch]
        $Forever
    )

    $Cache = @{
        Type       = [System.String]::format("{0}.{1}", (Get-GithubAccountContext).cacheRef, (Get-GithubUser).login)
        Identifier = $Identifier
        Forever    = $Forever
        Alive      = $Alive
        Object     = $Object
    }
    return Set-UtilsCache @Cache
}