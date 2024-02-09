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
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
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

        $user = Set-UtilsCache -Object $user -Alive 1440 -Identifier "git.user.$((Get-GithubAccountContext -Account $Account).cacheRef)"
    }
    return $user
}