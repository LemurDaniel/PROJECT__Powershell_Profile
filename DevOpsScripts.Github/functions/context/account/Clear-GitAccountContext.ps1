<#
    .SYNOPSIS
    Remove an Git account context and its associated pat.

    .DESCRIPTION
    Remove an Git account context and its associated pat.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current Git Context in use.

    .LINK
        
#>
function Clear-GitAccountContext {

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
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
        $Account
    )

    $Accounts = Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable

    if ($PSCmdlet.ShouldProcess($Account, "Clear")) {
        Clear-GitPAT -Account $Account -Clear
        $Accounts.Remove($Account)
    }

    return Save-SecureStringToFile -Identifier git.accounts.all -Object $Accounts # -Forever
}