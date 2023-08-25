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
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubAccountContext -ListAvailable).name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            }
        )]
        $Account,

        [Parameter()]
        [switch]
        $Refresh
    )

    $user = Get-UtilsCache -Identifier "git.user.$((Get-GithubAccountContext -Account $Account).cacheRef)"
    if (!$user -OR $Refresh) {
        $user = Invoke-GithubRest -Method GET -API 'user' -Account $Account
        $user.email = (Invoke-GithubRest -Method GET -API 'user/emails' -Account $Account)
        | Where-Object -Property primary -EQ $true 
        | Select-Object -First 1 -ExpandProperty email

        $user = Set-UtilsCache -Object $user -Identifier "git.user.$((Get-GithubAccountContext -Account $Account).cacheRef)"
    }
    return $user
}