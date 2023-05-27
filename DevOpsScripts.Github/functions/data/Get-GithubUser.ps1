<#
    .SYNOPSIS
    Get data about the Githubuser connected to pat.

    .DESCRIPTION
    Get data about the Githubuser connected to pat.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    gihutuser

    
    .LINK
        
#>

function Get-GithubUser {

    param(
        [Parameter()]
        [switch]
        $Refresh
    )

    $user = Get-UtilsCache -Type User -Identifier git
    if (!$user -OR $Refresh) {
        $user = Invoke-GithubRest -Method GET -API 'user'
        $user.email = (Invoke-GithubRest -Method GET -API 'user/emails')
        | Where-Object -Property primary -EQ $true 
        | Select-Object -First 1 -ExpandProperty email

        $user = Set-UtilsCache -Object $user -Type User -Identifier git
    }
    return $user
}