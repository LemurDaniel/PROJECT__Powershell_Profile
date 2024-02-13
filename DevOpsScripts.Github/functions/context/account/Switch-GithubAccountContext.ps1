<#
    .SYNOPSIS
    Get Information about a Repository in a Context.

    .DESCRIPTION
    Get Information about a Repository in a Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Switch-GithubAccountContext {

    [Alias('git-swa')]
    param(
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [System.String]
        [Alias('a')]
        $Account
    )


    return Set-UtilsCache -Identifier context.accounts.current -Object $Account -Forever

}