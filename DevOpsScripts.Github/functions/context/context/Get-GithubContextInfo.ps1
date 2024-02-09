<#
    .SYNOPSIS
    Get Information about a Github a Context.

    .DESCRIPTION
    Get Information about a Github a Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Information about the Repository.

    .EXAMPLE

    Get Info about the current Context:

    PS> Get-GithubContextInfo

    .EXAMPLE

    Get Info about another Context:

    PS> Get-GithubContextInfo <autocomplete_context>

    .LINK
        
#>

function Get-GithubContextInfo {

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
        $Context,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Context = [System.String]::IsNullOrEmpty($Context) ? (Get-GithubContext -Account $Account) : $Context

    return Get-GithubContexts -Account $Account -Refresh:$Refresh
    | Where-Object -Property login -EQ $Context
    | Select-Object *, @{
        Name       = 'repositories';
        Expression = {
            Get-GithubRepositories -Account $Account -Context $Context -Refresh:$Refresh
        }
    }

}
