<#
    .SYNOPSIS
    Add a Git account and a PAT associated with it.

    .DESCRIPTION
    Add a Git account and a PAT associated with it.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current Git Context in use.

    .LINK
        
#>
function Get-GitContext {

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

    $Context = Get-GitCache -Identifier git.context -Account $Account

    if ($null -eq $Context) {
        $Context = Switch-GitContext -Account $Account -Context (Get-GitUser -Account $Account).login
    }

    return $Context
}