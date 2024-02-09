<#
    .SYNOPSIS
    Remove an github account context and its associated pat.

    .DESCRIPTION
    Remove an github account context and its associated pat.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Clear-GithubAccountContext {

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
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
        $Account
    )

    $Accounts = Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable

    if ($PSCmdlet.ShouldProcess($Account, "Clear")) {
        Clear-GithubPAT -Account $Account -Clear
        $Accounts.Remove($Account)
    }

    return Save-SecureStringToFile -Identifier git.accounts.all -Object $Accounts # -Forever
}