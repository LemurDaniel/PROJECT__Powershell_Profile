
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

    [Alias('github-swc')]
    param(
        [Parameter(
            Position = 1,
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
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty( $_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            },
            ErrorMessage = 'Not a valid account.'
        )]
        $Account,

        # The specific Context to use
        [parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
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