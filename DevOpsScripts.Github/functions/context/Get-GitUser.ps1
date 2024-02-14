<#
    .SYNOPSIS
    Get data about the Gituser connected to pat.

    .DESCRIPTION
    Get data about the Gituser connected to pat.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    gihutuser

    
    .LINK
        
#>

function Get-GitUser {

    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        [Parameter()]
        [switch]
        $Refresh
    )

    $user = Get-UtilsCache -Identifier "git.user.$((Get-GitAccountContext -Account $Account).cacheRef)"
    if (!$user -OR $Refresh) {
        $user = Invoke-GitRest -Method GET -API 'user' -Account $Account
        $user.email = (Invoke-GitRest -Method GET -API 'user/emails' -Account $Account)
        | Where-Object -Property primary -EQ $true 
        | Select-Object -First 1 -ExpandProperty email

        $user = Set-UtilsCache -Object $user -Alive 1440 -Identifier "git.user.$((Get-GitAccountContext -Account $Account).cacheRef)"
    }
    return $user
}