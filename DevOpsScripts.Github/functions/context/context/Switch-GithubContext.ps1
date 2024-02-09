
<#
    .SYNOPSIS
    Switch the current github context or context and account.

    .DESCRIPTION
    Switch the current github context or context and account.
    All commands use the current context as default.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .EXAMPLE

    Switch the context in the current account:

    PS> github-swc <autocompleted_context>

    .EXAMPLE

    Switch the account and context: 

    PS> github-swc -Account <autocompleted_account>  <autocompleted_context>

    .LINK
        
#>
function Switch-GithubContext {

    [Alias('git-swc')]
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

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context
    )

    if ($Context -notin (Get-GithubContexts -Account $Account).login) {
        throw "Context '$Context' not existent in '$Account'"
    }

    $Account = [System.String]::IsNullOrEmpty($Account) ? (Get-GithubAccountContext).name : $Account
    $Account = Switch-GithubAccountContext -Account $Account
    $Context = Set-GithubCache -Object $Context -Identifier git.context -Account $Account -Forever

    Write-Host -ForegroundColor Magenta "Account: $Account"
    Write-Host -ForegroundColor Magenta "Context: $Context"

}