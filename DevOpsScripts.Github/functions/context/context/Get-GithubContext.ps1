<#
    .SYNOPSIS
    Add a github account and a PAT associated with it.

    .DESCRIPTION
    Add a github account and a PAT associated with it.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Get-GithubContext {

    param(
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account
    )

    $Context = Get-GithubCache -Identifier git.context -Account $Account

    if ($null -eq $Context) {
        $Context = Switch-GithubContext -Account $Account -Context (Get-GithubUser -Account $Account).login
    }

    return $Context
}