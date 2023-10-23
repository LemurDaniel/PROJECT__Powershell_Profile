
<#
    .SYNOPSIS
    Returns a list of all available emojies from the github api.

    .DESCRIPTION
    Returns a list of all available emojies from the github api.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Github Pat

    
    .LINK
        
#>
function Get-GithubEmojies {

    param(
        [Parameter()]
        [switch]
        $Refresh
    )
    
    $Identifier = "github.emolies.list"
    $emojies = Get-UtilsCache -Identifier $Identifier -AsHashtable

    if ($null -EQ $emojies -OR $Refresh) {
        $emojies = Invoke-GithubRest -Method GET -URL "https://api.github.com/emojis"
        $emojies = Set-UtilsCache -Object $emojies -Identifier $Identifier
        $emojies = Get-UtilsCache -Identifier $Identifier -AsHashtable
    }

    return $emojies

}