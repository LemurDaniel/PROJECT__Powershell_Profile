
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
    
    $Identifier = "emolies.list"
    $emojies = Get-GithubCache -Identifier $Identifier -AsHashtable

    if ($null -EQ $emojies -OR $Refresh) {
        $emojies = Invoke-GithubRest -Method GET -API "/emojis"
        $emojies = Set-GithubCache -Object $emojies -Identifier $Identifier
        $emojies = Get-GithubCache -Identifier $Identifier -AsHashtable
    }

    return $emojies

}