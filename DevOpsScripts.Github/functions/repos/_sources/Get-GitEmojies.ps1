
<#
    .SYNOPSIS
    Returns a list of all available emojies from the Git api.

    .DESCRIPTION
    Returns a list of all available emojies from the Git api.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Git Pat

    
    .LINK
        
#>
function Get-GitEmojies {

    param(
        [Parameter()]
        [switch]
        $Refresh
    )
    
    $Identifier = "Git.emolies.list"
    $emojies = Get-UtilsCache -Identifier $Identifier -AsHashtable

    if ($null -EQ $emojies -OR $Refresh) {
        $emojies = Invoke-RestMethod -Uri "https://api.Github.com/emojis"
        $emojies = Set-UtilsCache -Object $emojies -Identifier $Identifier -Forever
        $emojies = Get-UtilsCache -Identifier $Identifier -AsHashtable
    }

    return $emojies

}