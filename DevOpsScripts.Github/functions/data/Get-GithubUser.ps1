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

    $user = Get-UtilsCache -Identifier "git.user.$((Get-GithubAccountContext).cacheRef)"
    if (!$user -OR $Refresh) {
        $user = Invoke-GithubRest -Method GET -API 'user'
        $user.email = (Invoke-GithubRest -Method GET -API 'user/emails')
        | Where-Object -Property primary -EQ $true 
        | Select-Object -First 1 -ExpandProperty email

        $user = Set-UtilsCache -Object $user -Identifier "git.user.$((Get-GithubAccountContext).cacheRef)"
    }
    return $user
}