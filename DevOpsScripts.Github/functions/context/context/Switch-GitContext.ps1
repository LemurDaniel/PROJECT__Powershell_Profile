
<#
    .SYNOPSIS
    Switch the current Git context or context and account.

    .DESCRIPTION
    Switch the current Git context or context and account.
    All commands use the current context as default.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current Git Context in use.

    .EXAMPLE

    Switch the context in the current account:

    PS> Git-swc <autocompleted_context>

    .EXAMPLE

    Switch the account and context: 

    PS> Git-swc -Account <autocompleted_account>  <autocompleted_context>

    .LINK
        
#>
function Switch-GitContext {

    [Alias('git-swc')]
    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Git Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context
    )

    if ($Context -notin (Get-GitContexts -Account $Account).login) {
        throw "Context '$Context' not existent in '$Account'"
    }

    $Account = [System.String]::IsNullOrEmpty($Account) ? (Get-GitAccountContext).name : $Account
    $Account = Switch-GitAccountContext -Account $Account
    $Context = Set-GitCache -Object $Context -Identifier git.context -Account $Account -Forever

    Write-Host -ForegroundColor Magenta "Account: $Account"
    Write-Host -ForegroundColor Magenta "Context: $Context"

}