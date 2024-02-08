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
        $Forever,

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
        Type       = [System.String]::format("{0}.{1}", (Get-GithubAccountContext -Account $Account).cacheRef, (Get-GithubUser -Account $Account).login)
        Identifier = (@($Identifier, $Context, $Repository) | Where-Object { ![System.String]::IsNullOrEmpty($_) }) -join '.'
        Forever    = $Forever
        Alive      = $Alive
        Object     = $Object
    }
    
    return Set-UtilsCache @Cache
}